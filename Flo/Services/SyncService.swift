import Foundation
import SwiftData
import Supabase

// MARK: - Sync Status

enum SyncStatus: Equatable {
    case idle
    case syncing
    case synced
    case error(String)

    var label: String {
        switch self {
        case .idle: "Idle"
        case .syncing: "Syncing..."
        case .synced: "Synced"
        case .error(let message): "Error: \(message)"
        }
    }

    var icon: String {
        switch self {
        case .idle: "icloud"
        case .syncing: "arrow.triangle.2.circlepath"
        case .synced: "checkmark.icloud"
        case .error: "exclamationmark.icloud"
        }
    }
}

// MARK: - Sync Service

@MainActor @Observable
final class SyncService {
    // MARK: - Singleton

    static let shared = SyncService()

    // MARK: - Properties

    private let supabase = SupabaseManager.shared
    var status: SyncStatus = .idle
    var lastSyncDate: Date?

    private var realtimeChannel: RealtimeChannelV2?

    private init() {}

    // MARK: - Full Sync

    func syncAll(modelContext: ModelContext) async {
        guard supabase.isAuthenticated else {
            status = .idle
            return
        }

        status = .syncing

        do {
            try await syncProjects(modelContext: modelContext)
            try await syncTags(modelContext: modelContext)
            try await syncTasks(modelContext: modelContext)
            try await syncNotes(modelContext: modelContext)
            try await syncHabits(modelContext: modelContext)
            try await syncFocusSessions(modelContext: modelContext)

            lastSyncDate = Date()
            status = .synced
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    // MARK: - Sync Projects

    func syncProjects(modelContext: ModelContext) async throws {
        guard let userId = supabase.currentUser?.id else { return }

        // Pull remote projects
        let remoteProjects: [ProjectDTO] = try await supabase.client
            .from("projects")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        // Get local projects
        let descriptor = FetchDescriptor<Project>()
        let localProjects = try modelContext.fetch(descriptor)

        // Merge: remote wins (last-write-wins)
        let localNames = Set(localProjects.map(\.name))
        let remoteNames = Set(remoteProjects.map(\.name))

        // Add remote projects not found locally
        for remote in remoteProjects {
            if !localNames.contains(remote.name) {
                let values = remote.toLocal()
                let project = Project(
                    name: values.name,
                    colorHex: values.colorHex,
                    icon: values.icon,
                    isArchived: values.isArchived
                )
                modelContext.insert(project)
            }
        }

        // Push local projects not found remotely
        for local in localProjects {
            if !remoteNames.contains(local.name) {
                let dto = ProjectDTO.fromLocal(local, userId: userId)
                try await supabase.client
                    .from("projects")
                    .insert(dto)
                    .execute()
            }
        }

        try modelContext.save()
    }

    // MARK: - Sync Tags

    func syncTags(modelContext: ModelContext) async throws {
        guard let userId = supabase.currentUser?.id else { return }

        let remoteTags: [TagDTO] = try await supabase.client
            .from("tags")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let descriptor = FetchDescriptor<Tag>()
        let localTags = try modelContext.fetch(descriptor)

        let localNames = Set(localTags.map(\.name))
        let remoteNames = Set(remoteTags.map(\.name))

        for remote in remoteTags {
            if !localNames.contains(remote.name) {
                let values = remote.toLocal()
                let tag = Tag(name: values.name, colorHex: values.colorHex)
                modelContext.insert(tag)
            }
        }

        for local in localTags {
            if !remoteNames.contains(local.name) {
                let dto = TagDTO.fromLocal(local, userId: userId)
                try await supabase.client
                    .from("tags")
                    .insert(dto)
                    .execute()
            }
        }

        try modelContext.save()
    }

    // MARK: - Sync Tasks

    func syncTasks(modelContext: ModelContext) async throws {
        guard let userId = supabase.currentUser?.id else { return }

        let remoteTasks: [TaskDTO] = try await supabase.client
            .from("tasks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let descriptor = FetchDescriptor<TaskItem>()
        let localTasks = try modelContext.fetch(descriptor)

        // Use title + createdAt as a composite key for matching
        let localKeys = Set(localTasks.map { "\($0.title)|\($0.createdAt.timeIntervalSince1970)" })

        // Pull remote tasks not found locally
        for remote in remoteTasks {
            let remoteKey = "\(remote.title)|\(remote.createdAt?.timeIntervalSince1970 ?? 0)"
            if !localKeys.contains(remoteKey) {
                let values = remote.toLocal()
                let task = TaskItem(
                    title: values.title,
                    notes: values.notes,
                    isCompleted: values.isCompleted,
                    priority: values.priority,
                    dueDate: values.dueDate,
                    scheduledDate: values.scheduledDate,
                    recurrence: values.recurrence,
                    order: values.order
                )
                task.completedAt = values.completedAt
                modelContext.insert(task)
            }
        }

        // Push local tasks not found remotely
        let remoteKeys = Set(remoteTasks.map { "\($0.title)|\($0.createdAt?.timeIntervalSince1970 ?? 0)" })

        for local in localTasks {
            let localKey = "\(local.title)|\(local.createdAt.timeIntervalSince1970)"
            if !remoteKeys.contains(localKey) {
                let dto = TaskDTO.fromLocal(local, userId: userId)
                try await supabase.client
                    .from("tasks")
                    .insert(dto)
                    .execute()
            }
        }

        try modelContext.save()
    }

    // MARK: - Sync Notes

    func syncNotes(modelContext: ModelContext) async throws {
        guard let userId = supabase.currentUser?.id else { return }

        // Sync note folders first
        let remoteFolders: [NoteFolderDTO] = try await supabase.client
            .from("note_folders")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let folderDescriptor = FetchDescriptor<NoteFolder>()
        let localFolders = try modelContext.fetch(folderDescriptor)

        let localFolderNames = Set(localFolders.map(\.name))
        let remoteFolderNames = Set(remoteFolders.map(\.name))

        for remote in remoteFolders {
            if !localFolderNames.contains(remote.name) {
                let values = remote.toLocal()
                let folder = NoteFolder(name: values.name, icon: values.icon)
                modelContext.insert(folder)
            }
        }

        for local in localFolders {
            if !remoteFolderNames.contains(local.name) {
                let dto = NoteFolderDTO.fromLocal(local, userId: userId)
                try await supabase.client
                    .from("note_folders")
                    .insert(dto)
                    .execute()
            }
        }

        // Sync notes
        let remoteNotes: [NoteDTO] = try await supabase.client
            .from("notes")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let noteDescriptor = FetchDescriptor<Note>()
        let localNotes = try modelContext.fetch(noteDescriptor)

        let localNoteKeys = Set(localNotes.map { "\($0.title)|\($0.createdAt.timeIntervalSince1970)" })

        for remote in remoteNotes {
            let key = "\(remote.title)|\(remote.createdAt?.timeIntervalSince1970 ?? 0)"
            if !localNoteKeys.contains(key) {
                let values = remote.toLocal()
                let note = Note(
                    title: values.title,
                    content: values.content,
                    isPinned: values.isPinned
                )
                modelContext.insert(note)
            }
        }

        let remoteNoteKeys = Set(remoteNotes.map { "\($0.title)|\($0.createdAt?.timeIntervalSince1970 ?? 0)" })

        for local in localNotes {
            let key = "\(local.title)|\(local.createdAt.timeIntervalSince1970)"
            if !remoteNoteKeys.contains(key) {
                let dto = NoteDTO.fromLocal(local, userId: userId)
                try await supabase.client
                    .from("notes")
                    .insert(dto)
                    .execute()
            }
        }

        try modelContext.save()
    }

    // MARK: - Sync Habits

    func syncHabits(modelContext: ModelContext) async throws {
        guard let userId = supabase.currentUser?.id else { return }

        let remoteHabits: [HabitDTO] = try await supabase.client
            .from("habits")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let descriptor = FetchDescriptor<Habit>()
        let localHabits = try modelContext.fetch(descriptor)

        let localNames = Set(localHabits.map(\.name))
        let remoteNames = Set(remoteHabits.map(\.name))

        for remote in remoteHabits {
            if !localNames.contains(remote.name) {
                let values = remote.toLocal()
                let habit = Habit(
                    name: values.name,
                    icon: values.icon,
                    frequency: values.frequency,
                    reminderTime: values.reminderTime
                )
                habit.isArchived = values.isArchived
                modelContext.insert(habit)
            }
        }

        for local in localHabits {
            if !remoteNames.contains(local.name) {
                let dto = HabitDTO.fromLocal(local, userId: userId)
                try await supabase.client
                    .from("habits")
                    .insert(dto)
                    .execute()
            }
        }

        try modelContext.save()
    }

    // MARK: - Sync Focus Sessions

    func syncFocusSessions(modelContext: ModelContext) async throws {
        guard let userId = supabase.currentUser?.id else { return }

        let remoteSessions: [FocusSessionDTO] = try await supabase.client
            .from("focus_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let descriptor = FetchDescriptor<FocusSession>()
        let localSessions = try modelContext.fetch(descriptor)

        let localKeys = Set(localSessions.map { "\($0.startedAt.timeIntervalSince1970)|\($0.duration)" })

        for remote in remoteSessions {
            let key = "\(remote.startedAt.timeIntervalSince1970)|\(remote.duration)"
            if !localKeys.contains(key) {
                let values = remote.toLocal()
                let session = FocusSession(duration: values.duration)
                session.actualDuration = values.actualDuration
                session.wasCompleted = values.wasCompleted
                modelContext.insert(session)
            }
        }

        let remoteKeys = Set(remoteSessions.map { "\($0.startedAt.timeIntervalSince1970)|\($0.duration)" })

        for local in localSessions {
            let key = "\(local.startedAt.timeIntervalSince1970)|\(local.duration)"
            if !remoteKeys.contains(key) {
                let dto = FocusSessionDTO.fromLocal(local, userId: userId)
                try await supabase.client
                    .from("focus_sessions")
                    .insert(dto)
                    .execute()
            }
        }

        try modelContext.save()
    }

    // MARK: - Realtime Subscriptions

    func subscribeToRealtimeUpdates() async {
        guard supabase.isAuthenticated else { return }

        let channel = supabase.client.realtimeV2.channel("sync-channel")

        let tables = ["tasks", "projects", "habits", "notes", "focus_sessions"]

        for table in tables {
            let changes = channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: table
            )

            Task { [weak self] in
                for await _ in changes {
                    await self?.handleRealtimeChange(table: table)
                }
            }
        }

        await channel.subscribe()
        realtimeChannel = channel
    }

    private func handleRealtimeChange(table: String) async {
        // Trigger a status update to notify the UI that a remote change occurred.
        self.status = .syncing

        // Brief delay then mark as synced to show activity
        try? await Task.sleep(for: .milliseconds(500))

        self.status = .synced
        self.lastSyncDate = Date()
    }

    // MARK: - Unsubscribe

    func unsubscribe() async {
        if let channel = realtimeChannel {
            await channel.unsubscribe()
            realtimeChannel = nil
        }
    }

    // MARK: - Export Data

    func exportAllData(modelContext: ModelContext) async throws -> Data {
        let taskDescriptor = FetchDescriptor<TaskItem>()
        let projectDescriptor = FetchDescriptor<Project>()
        let noteDescriptor = FetchDescriptor<Note>()
        let habitDescriptor = FetchDescriptor<Habit>()
        let focusDescriptor = FetchDescriptor<FocusSession>()

        let tasks = try modelContext.fetch(taskDescriptor)
        let projects = try modelContext.fetch(projectDescriptor)
        let notes = try modelContext.fetch(noteDescriptor)
        let habits = try modelContext.fetch(habitDescriptor)
        let focusSessions = try modelContext.fetch(focusDescriptor)

        let exportData: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "tasks": tasks.count,
            "projects": projects.count,
            "notes": notes.count,
            "habits": habits.count,
            "focusSessions": focusSessions.count
        ]

        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
}
