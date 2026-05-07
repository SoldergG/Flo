import Foundation

// MARK: - Profile DTO

struct ProfileDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var displayName: String?
    var avatarUrl: String?
    var email: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case email
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Project DTO

struct ProjectDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var userId: UUID
    var name: String
    var colorHex: String
    var icon: String
    var isArchived: Bool
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case colorHex = "color_hex"
        case icon
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toLocal() -> (name: String, colorHex: String, icon: String, isArchived: Bool) {
        (name: name, colorHex: colorHex, icon: icon, isArchived: isArchived)
    }

    static func fromLocal(_ project: Project, userId: UUID) -> ProjectDTO {
        ProjectDTO(
            id: UUID(),
            userId: userId,
            name: project.name,
            colorHex: project.colorHex,
            icon: project.icon,
            isArchived: project.isArchived,
            createdAt: project.createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Tag DTO

struct TagDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var userId: UUID
    var name: String
    var colorHex: String
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case colorHex = "color_hex"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toLocal() -> (name: String, colorHex: String) {
        (name: name, colorHex: colorHex)
    }

    static func fromLocal(_ tag: Tag, userId: UUID) -> TagDTO {
        TagDTO(
            id: UUID(),
            userId: userId,
            name: tag.name,
            colorHex: tag.colorHex,
            createdAt: nil,
            updatedAt: Date()
        )
    }
}

// MARK: - Task DTO

struct TaskDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var userId: UUID
    var projectId: UUID?
    var parentTaskId: UUID?
    var title: String
    var notes: String
    var isCompleted: Bool
    var priority: Int
    var dueDate: Date?
    var scheduledDate: Date?
    var recurrence: String?
    var completedAt: Date?
    var order: Int
    var kanbanStatus: String
    var isTemplate: Bool
    var templateName: String?
    var energyLevel: String?
    var estimatedMinutes: Int?
    var actualMinutes: Int?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case projectId = "project_id"
        case parentTaskId = "parent_task_id"
        case title
        case notes
        case isCompleted = "is_completed"
        case priority
        case dueDate = "due_date"
        case scheduledDate = "scheduled_date"
        case recurrence
        case completedAt = "completed_at"
        case order
        case kanbanStatus = "kanban_status"
        case isTemplate = "is_template"
        case templateName = "template_name"
        case energyLevel = "energy_level"
        case estimatedMinutes = "estimated_minutes"
        case actualMinutes = "actual_minutes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toLocal() -> (title: String, notes: String, isCompleted: Bool, priority: Priority, dueDate: Date?, scheduledDate: Date?, recurrence: Recurrence?, completedAt: Date?, order: Int, kanbanStatus: String, isTemplate: Bool, templateName: String?, energyLevel: String?, estimatedMinutes: Int?, actualMinutes: Int?) {
        let mappedPriority = Priority(rawValue: priority) ?? .medium
        let mappedRecurrence = recurrence.flatMap { Recurrence(rawValue: $0) }
        return (
            title: title,
            notes: notes,
            isCompleted: isCompleted,
            priority: mappedPriority,
            dueDate: dueDate,
            scheduledDate: scheduledDate,
            recurrence: mappedRecurrence,
            completedAt: completedAt,
            order: order,
            kanbanStatus: kanbanStatus,
            isTemplate: isTemplate,
            templateName: templateName,
            energyLevel: energyLevel,
            estimatedMinutes: estimatedMinutes,
            actualMinutes: actualMinutes
        )
    }

    static func fromLocal(_ task: TaskItem, userId: UUID, projectId: UUID? = nil, parentTaskId: UUID? = nil) -> TaskDTO {
        TaskDTO(
            id: UUID(),
            userId: userId,
            projectId: projectId,
            parentTaskId: parentTaskId,
            title: task.title,
            notes: task.notes,
            isCompleted: task.isCompleted,
            priority: task.priority.rawValue,
            dueDate: task.dueDate,
            scheduledDate: task.scheduledDate,
            recurrence: task.recurrence?.rawValue,
            completedAt: task.completedAt,
            order: task.order,
            kanbanStatus: task.kanbanStatus,
            isTemplate: task.isTemplate,
            templateName: task.templateName,
            energyLevel: task.energyLevel,
            estimatedMinutes: task.estimatedMinutes,
            actualMinutes: task.actualMinutes,
            createdAt: task.createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Task Tag DTO (junction table)

struct TaskTagDTO: Codable, Sendable {
    let taskId: UUID
    let tagId: UUID

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case tagId = "tag_id"
    }
}

// MARK: - Task Dependency DTO

struct TaskDependencyDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var taskId: UUID
    var dependsOnTaskId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case dependsOnTaskId = "depends_on_task_id"
    }
}

// MARK: - Note Folder DTO

struct NoteFolderDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var userId: UUID
    var name: String
    var icon: String
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case icon
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toLocal() -> (name: String, icon: String) {
        (name: name, icon: icon)
    }

    static func fromLocal(_ folder: NoteFolder, userId: UUID) -> NoteFolderDTO {
        NoteFolderDTO(
            id: UUID(),
            userId: userId,
            name: folder.name,
            icon: folder.icon,
            createdAt: folder.createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Note DTO

struct NoteDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var userId: UUID
    var folderId: UUID?
    var title: String
    var content: String
    var isPinned: Bool
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case folderId = "folder_id"
        case title
        case content
        case isPinned = "is_pinned"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toLocal() -> (title: String, content: String, isPinned: Bool) {
        (title: title, content: content, isPinned: isPinned)
    }

    static func fromLocal(_ note: Note, userId: UUID, folderId: UUID? = nil) -> NoteDTO {
        NoteDTO(
            id: UUID(),
            userId: userId,
            folderId: folderId,
            title: note.title,
            content: note.content,
            isPinned: note.isPinned,
            createdAt: note.createdAt,
            updatedAt: note.updatedAt
        )
    }
}

// MARK: - Note Link DTO

struct NoteLinkDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var sourceNoteId: UUID
    var targetNoteId: UUID
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case sourceNoteId = "source_note_id"
        case targetNoteId = "target_note_id"
        case createdAt = "created_at"
    }
}

// MARK: - Habit DTO

struct HabitDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var userId: UUID
    var name: String
    var icon: String
    var frequency: String
    var reminderTime: Date?
    var isArchived: Bool
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case icon
        case frequency
        case reminderTime = "reminder_time"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toLocal() -> (name: String, icon: String, frequency: Frequency, reminderTime: Date?, isArchived: Bool) {
        let mappedFrequency = Frequency(rawValue: frequency) ?? .daily
        return (
            name: name,
            icon: icon,
            frequency: mappedFrequency,
            reminderTime: reminderTime,
            isArchived: isArchived
        )
    }

    static func fromLocal(_ habit: Habit, userId: UUID) -> HabitDTO {
        HabitDTO(
            id: UUID(),
            userId: userId,
            name: habit.name,
            icon: habit.icon,
            frequency: habit.frequency.rawValue,
            reminderTime: habit.reminderTime,
            isArchived: habit.isArchived,
            createdAt: habit.createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Habit Completion DTO

struct HabitCompletionDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var habitId: UUID
    var date: Date
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case habitId = "habit_id"
        case date
        case createdAt = "created_at"
    }

    func toLocal() -> Date {
        date
    }

    static func fromLocal(_ completion: HabitCompletion, habitId: UUID) -> HabitCompletionDTO {
        HabitCompletionDTO(
            id: UUID(),
            habitId: habitId,
            date: completion.date,
            createdAt: Date()
        )
    }
}

// MARK: - Focus Session DTO

struct FocusSessionDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var userId: UUID
    var taskId: UUID?
    var startedAt: Date
    var duration: TimeInterval
    var actualDuration: TimeInterval?
    var wasCompleted: Bool
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case taskId = "task_id"
        case startedAt = "started_at"
        case duration
        case actualDuration = "actual_duration"
        case wasCompleted = "was_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toLocal() -> (startedAt: Date, duration: TimeInterval, actualDuration: TimeInterval?, wasCompleted: Bool) {
        (startedAt: startedAt, duration: duration, actualDuration: actualDuration, wasCompleted: wasCompleted)
    }

    static func fromLocal(_ session: FocusSession, userId: UUID, taskId: UUID? = nil) -> FocusSessionDTO {
        FocusSessionDTO(
            id: UUID(),
            userId: userId,
            taskId: taskId,
            startedAt: session.startedAt,
            duration: session.duration,
            actualDuration: session.actualDuration,
            wasCompleted: session.wasCompleted,
            createdAt: session.createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Focus Preset DTO

struct FocusPresetDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var userId: UUID
    var name: String
    var durationMinutes: Int
    var icon: String?
    var colorHex: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case durationMinutes = "duration_minutes"
        case icon
        case colorHex = "color_hex"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Mood Entry DTO

struct MoodEntryDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var userId: UUID
    var mood: Int
    var note: String?
    var date: Date
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mood
        case note
        case date
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Journal Entry DTO

struct JournalEntryDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var userId: UUID
    var title: String
    var content: String
    var mood: Int?
    var date: Date
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case content
        case mood
        case date
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Daily Score DTO

struct DailyScoreDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var userId: UUID
    var date: Date
    var tasksCompleted: Int
    var habitsCompleted: Int
    var focusMinutes: Int
    var score: Double
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case tasksCompleted = "tasks_completed"
        case habitsCompleted = "habits_completed"
        case focusMinutes = "focus_minutes"
        case score
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Smart List DTO

struct SmartListDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var userId: UUID
    var name: String
    var icon: String?
    var filterJson: String
    var sortBy: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case icon
        case filterJson = "filter_json"
        case sortBy = "sort_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
