import Foundation
import SwiftData
import SwiftUI

@Observable
final class HabitViewModel {
    var showingAddHabit = false
    var selectedDate = Date.now

    func addHabit(name: String, icon: String, frequency: Frequency, context: ModelContext) {
        let habit = Habit(name: name, icon: icon, frequency: frequency)
        context.insert(habit)
        try? context.save()
    }

    func toggleCompletion(_ habit: Habit, context: ModelContext) {
        if habit.isCompletedToday {
            if let completion = habit.completions.first(where: { Calendar.current.isDateInToday($0.date) }) {
                context.delete(completion)
            }
        } else {
            let completion = HabitCompletion(date: .now)
            completion.habit = habit
            habit.completions.append(completion)
            context.insert(completion)
        }
        try? context.save()
    }

    func deleteHabit(_ habit: Habit, context: ModelContext) {
        context.delete(habit)
        try? context.save()
    }

    var weekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
}
