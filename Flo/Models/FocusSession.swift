import Foundation
import SwiftData

@Model
final class FocusSession {
    var startedAt: Date
    var duration: TimeInterval
    var actualDuration: TimeInterval?
    var wasCompleted: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var task: TaskItem?

    init(
        duration: TimeInterval,
        task: TaskItem? = nil
    ) {
        self.startedAt = .now
        self.duration = duration
        self.actualDuration = nil
        self.wasCompleted = false
        self.createdAt = .now
        self.task = task
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }

    var actualMinutes: Int {
        Int((actualDuration ?? 0) / 60)
    }
}
