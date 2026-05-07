import Foundation
import SwiftData

@Model
final class TaskItem {
    var title: String
    var notes: String
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?
    var scheduledDate: Date?
    var recurrence: Recurrence?
    var completedAt: Date?
    var createdAt: Date
    var order: Int

    // New fields for 50+ features
    var kanbanStatus: String
    var isTemplate: Bool
    var templateName: String?
    var energyLevel: String?
    var estimatedMinutes: Int?
    var actualMinutes: Int?
    var supabaseId: String?
    var lastSyncedAt: Date?

    @Relationship(deleteRule: .nullify, inverse: \TaskItem.parentTask)
    var subtasks: [TaskItem]

    @Relationship(deleteRule: .nullify)
    var parentTask: TaskItem?

    @Relationship(deleteRule: .nullify, inverse: \Project.tasks)
    var project: Project?

    @Relationship(deleteRule: .nullify, inverse: \Tag.tasks)
    var tags: [Tag]

    init(
        title: String,
        notes: String = "",
        isCompleted: Bool = false,
        priority: Priority = .medium,
        dueDate: Date? = nil,
        scheduledDate: Date? = nil,
        recurrence: Recurrence? = nil,
        order: Int = 0,
        project: Project? = nil,
        kanbanStatus: String = "todo",
        isTemplate: Bool = false,
        templateName: String? = nil
    ) {
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.priority = priority
        self.dueDate = dueDate
        self.scheduledDate = scheduledDate
        self.recurrence = recurrence
        self.completedAt = nil
        self.createdAt = .now
        self.order = order
        self.kanbanStatus = kanbanStatus
        self.isTemplate = isTemplate
        self.templateName = templateName
        self.energyLevel = nil
        self.estimatedMinutes = nil
        self.actualMinutes = nil
        self.supabaseId = nil
        self.lastSyncedAt = nil
        self.subtasks = []
        self.parentTask = nil
        self.project = project
        self.tags = []
    }

    var isOverdue: Bool {
        guard let dueDate, !isCompleted else { return false }
        return dueDate < .now
    }

    var subtaskProgress: Double {
        guard !subtasks.isEmpty else { return isCompleted ? 1.0 : 0.0 }
        let completed = subtasks.filter(\.isCompleted).count
        return Double(completed) / Double(subtasks.count)
    }

    var isDueToday: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    var isDueThisWeek: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDate(dueDate, equalTo: .now, toGranularity: .weekOfYear)
    }

    var isUrgent: Bool {
        guard let dueDate else { return false }
        let hoursUntilDue = dueDate.timeIntervalSinceNow / 3600
        return hoursUntilDue < 48 && !isCompleted
    }

    var isImportant: Bool {
        priority == .high
    }

    var eisenhowerQuadrant: Int {
        switch (isUrgent, isImportant) {
        case (true, true): return 1
        case (false, true): return 2
        case (true, false): return 3
        case (false, false): return 4
        }
    }
}
