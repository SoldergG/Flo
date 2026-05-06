import Foundation
import SwiftData
import SwiftUI

@Model
final class Project {
    var name: String
    var colorHex: String
    var icon: String
    var isArchived: Bool
    var createdAt: Date

    var tasks: [TaskItem]

    init(
        name: String,
        colorHex: String = "D97757",
        icon: String = "folder.fill",
        isArchived: Bool = false
    ) {
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.isArchived = isArchived
        self.createdAt = .now
        self.tasks = []
    }

    var color: Color {
        Color(hex: colorHex)
    }

    var activeTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
    }

    var completedTasks: [TaskItem] {
        tasks.filter(\.isCompleted)
    }

    var completionRate: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(tasks.count)
    }
}
