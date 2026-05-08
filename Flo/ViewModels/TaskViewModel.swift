import Foundation
import SwiftData
import SwiftUI

@Observable
final class TaskViewModel {
    var showingAddTask = false
    var showingAddProject = false
    var editingTask: TaskItem? // FIX #40: track task being edited
    var selectedProject: Project?
    var searchText = ""
    var sortByPriority = false

    func addTask(
        title: String,
        notes: String = "",
        priority: Priority = .medium,
        dueDate: Date? = nil,
        project: Project? = nil,
        context: ModelContext
    ) {
        let task = TaskItem(
            title: title,
            notes: notes,
            priority: priority,
            dueDate: dueDate,
            project: project
        )
        context.insert(task)
        try? context.save()
    }

    func toggleComplete(_ task: TaskItem, context: ModelContext) {
        withAnimation(FloAnimations.springBouncy) {
            task.isCompleted.toggle()
            task.completedAt = task.isCompleted ? .now : nil
        }
        try? context.save()
    }

    func deleteTask(_ task: TaskItem, context: ModelContext) {
        context.delete(task)
        try? context.save()
    }

    func addProject(name: String, colorHex: String, icon: String, context: ModelContext) {
        let project = Project(name: name, colorHex: colorHex, icon: icon)
        context.insert(project)
        try? context.save()
    }

    func addSubtask(to parent: TaskItem, title: String, context: ModelContext) {
        let subtask = TaskItem(title: title, priority: parent.priority, project: parent.project)
        subtask.parentTask = parent
        parent.subtasks.append(subtask)
        context.insert(subtask)
        try? context.save()
    }
}
