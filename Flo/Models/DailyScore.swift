import Foundation
import SwiftData

@Model
final class DailyScore {
    var date: Date
    var tasksCompleted: Int
    var tasksTotal: Int
    var habitsCompleted: Int
    var habitsTotal: Int
    var focusMinutes: Int
    var productivityScore: Double
    var createdAt: Date
    var supabaseId: String?

    init(
        date: Date = .now,
        tasksCompleted: Int = 0,
        tasksTotal: Int = 0,
        habitsCompleted: Int = 0,
        habitsTotal: Int = 0,
        focusMinutes: Int = 0
    ) {
        self.date = date
        self.tasksCompleted = tasksCompleted
        self.tasksTotal = tasksTotal
        self.habitsCompleted = habitsCompleted
        self.habitsTotal = habitsTotal
        self.focusMinutes = focusMinutes
        self.productivityScore = DailyScore.calculateScore(
            tasksCompleted: tasksCompleted,
            tasksTotal: tasksTotal,
            habitsCompleted: habitsCompleted,
            habitsTotal: habitsTotal,
            focusMinutes: focusMinutes
        )
        self.createdAt = .now
        self.supabaseId = nil
    }

    static func calculateScore(
        tasksCompleted: Int, tasksTotal: Int,
        habitsCompleted: Int, habitsTotal: Int,
        focusMinutes: Int
    ) -> Double {
        let taskScore = tasksTotal > 0 ? (Double(tasksCompleted) / Double(tasksTotal)) * 40 : 20
        let habitScore = habitsTotal > 0 ? (Double(habitsCompleted) / Double(habitsTotal)) * 35 : 17.5
        let focusScore = min(Double(focusMinutes) / 120.0, 1.0) * 25
        return taskScore + habitScore + focusScore
    }

    var scoreLabel: String {
        switch productivityScore {
        case 80...: return "Excellent"
        case 60..<80: return "Great"
        case 40..<60: return "Good"
        case 20..<40: return "Fair"
        default: return "Getting Started"
        }
    }

    var taskCompletionRate: Double {
        guard tasksTotal > 0 else { return 0 }
        return Double(tasksCompleted) / Double(tasksTotal)
    }

    var habitCompletionRate: Double {
        guard habitsTotal > 0 else { return 0 }
        return Double(habitsCompleted) / Double(habitsTotal)
    }
}
