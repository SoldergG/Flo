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
        project: Project? = nil
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
}
