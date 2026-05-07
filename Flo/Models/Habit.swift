import Foundation
import SwiftData

@Model
final class Habit {
    var name: String
    var icon: String
    var colorHex: String
    var frequency: Frequency
    var category: String?
    var reminderTime: Date?
    var createdAt: Date
    var isArchived: Bool
    var streakFreezesRemaining: Int
    var order: Int
    var supabaseId: String?
    var lastSyncedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]

    init(
        name: String,
        icon: String = "star.fill",
        colorHex: String = "D97757",
        frequency: Frequency = .daily,
        category: String? = nil,
        reminderTime: Date? = nil
    ) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.frequency = frequency
        self.category = category
        self.reminderTime = reminderTime
        self.createdAt = .now
        self.isArchived = false
        self.streakFreezesRemaining = 0
        self.order = 0
        self.supabaseId = nil
        self.lastSyncedAt = nil
        self.completions = []
    }

    var isCompletedToday: Bool {
        completions.contains { Calendar.current.isDateInToday($0.date) }
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let sorted = completions.map(\.date).sorted(by: >)
        guard !sorted.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: .now)

        for date in sorted {
            let day = calendar.startOfDay(for: date)
            if day == checkDate {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if day < checkDate {
                break
            }
        }
        return streak
    }

    var bestStreak: Int {
        let calendar = Calendar.current
        let sorted = completions.map(\.date).sorted()
        guard !sorted.isEmpty else { return 0 }

        var best = 1
        var current = 1

        for i in 1..<sorted.count {
            let prev = calendar.startOfDay(for: sorted[i - 1])
            let curr = calendar.startOfDay(for: sorted[i])
            let diff = calendar.dateComponents([.day], from: prev, to: curr).day ?? 0

            if diff == 1 {
                current += 1
                best = max(best, current)
            } else if diff > 1 {
                current = 1
            }
        }
        return best
    }

    var totalCompletions: Int { completions.count }

    var completionRateByDayOfWeek: [Int: Double] {
        let calendar = Calendar.current
        var counts: [Int: Int] = [:]
        var totals: [Int: Int] = [:]
        for weekday in 1...7 { counts[weekday] = 0; totals[weekday] = 0 }

        let daysSinceCreation = max(1, calendar.dateComponents([.day], from: createdAt, to: .now).day ?? 1)
        let weeksActive = max(1, daysSinceCreation / 7)

        for weekday in 1...7 { totals[weekday] = weeksActive }
        for completion in completions {
            let weekday = calendar.component(.weekday, from: completion.date)
            counts[weekday, default: 0] += 1
        }

        var rates: [Int: Double] = [:]
        for weekday in 1...7 {
            rates[weekday] = Double(counts[weekday]!) / Double(totals[weekday]!)
        }
        return rates
    }

    func completionsInWeek(of date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        return completions.map(\.date).filter { $0 >= weekStart && $0 < weekEnd }
    }
}

@Model
final class HabitCompletion {
    var date: Date
    var isFreeze: Bool
    var habit: Habit?

    init(date: Date = .now, isFreeze: Bool = false) {
        self.date = date
        self.isFreeze = isFreeze
    }
}
