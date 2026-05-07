import Foundation
import SwiftData

@Model
final class FocusSession {
    var startedAt: Date
    var duration: TimeInterval
    var actualDuration: TimeInterval?
    var wasCompleted: Bool
    var ambientSound: String?
    var sessionNotes: String?
    var createdAt: Date
    var supabaseId: String?

    @Relationship(deleteRule: .nullify)
    var task: TaskItem?

    init(
        duration: TimeInterval,
        task: TaskItem? = nil,
        ambientSound: String? = nil
    ) {
        self.startedAt = .now
        self.duration = duration
        self.actualDuration = nil
        self.wasCompleted = false
        self.ambientSound = ambientSound
        self.sessionNotes = nil
        self.createdAt = .now
        self.supabaseId = nil
        self.task = task
    }

    var durationMinutes: Int { Int(duration / 60) }
    var actualMinutes: Int { Int((actualDuration ?? 0) / 60) }

    var formattedDuration: String {
        let minutes = durationMinutes
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}
