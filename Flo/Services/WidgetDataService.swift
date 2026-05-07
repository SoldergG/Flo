import Foundation
import SwiftData
import WidgetKit

@MainActor
final class WidgetDataService {
    static let shared = WidgetDataService()
    private let suiteName = "group.com.solderg.flo"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    func updateAllWidgets(context: ModelContext) {
        updateTaskData(context: context)
        updateHabitData(context: context)
        updateFocusData(context: context)
        updateScoreData(context: context)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func updateTaskData(context: ModelContext) {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { !$0.isCompleted && !$0.isTemplate },
            sortBy: [SortDescriptor(\TaskItem.dueDate)]
        )
        guard let tasks = try? context.fetch(descriptor) else { return }

        let today = Calendar.current.startOfDay(for: .now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let todayTasks = tasks.filter { task in
            if let scheduled = task.scheduledDate { return scheduled >= today && scheduled < tomorrow }
            if let due = task.dueDate { return due >= today && due < tomorrow }
            return Calendar.current.isDateInToday(task.createdAt)
        }

        let allTasksDescriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { !$0.isTemplate }
        )
        let allCount = (try? context.fetchCount(allTasksDescriptor)) ?? 0
        let completedDescriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.isCompleted && !$0.isTemplate }
        )
        let completedCount = (try? context.fetchCount(completedDescriptor)) ?? 0

        let widgetData: [String: Any] = [
            "totalTasks": allCount,
            "completedTasks": completedCount,
            "todayTaskCount": todayTasks.count,
            "todayCompletedCount": todayTasks.filter(\.isCompleted).count,
            "nextTaskTitle": tasks.first?.title ?? "",
            "nextTaskPriority": tasks.first?.priority.rawValue ?? 2,
            "nextTaskDueDate": tasks.first?.dueDate?.timeIntervalSince1970 ?? 0,
            "nextTaskProjectName": tasks.first?.project?.name ?? ""
        ]

        for (key, value) in widgetData {
            defaults?.set(value, forKey: "widget_task_\(key)")
        }
    }

    func updateHabitData(context: ModelContext) {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived }
        )
        guard let habits = try? context.fetch(descriptor) else { return }

        let totalHabits = habits.count
        let completedToday = habits.filter(\.isCompletedToday).count
        let bestStreak = habits.map(\.currentStreak).max() ?? 0

        let habitNames = habits.prefix(8).map { habit in
            [
                "name": habit.name,
                "icon": habit.icon,
                "completed": habit.isCompletedToday ? "true" : "false",
                "streak": "\(habit.currentStreak)"
            ]
        }

        if let encoded = try? JSONEncoder().encode(habitNames) {
            defaults?.set(encoded, forKey: "widget_habit_list")
        }

        defaults?.set(totalHabits, forKey: "widget_habit_total")
        defaults?.set(completedToday, forKey: "widget_habit_completed")
        defaults?.set(bestStreak, forKey: "widget_habit_bestStreak")
    }

    func updateFocusData(context: ModelContext) {
        let today = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.createdAt >= today }
        )
        let sessions = (try? context.fetch(descriptor)) ?? []

        let totalMinutes = sessions.reduce(0) { $0 + Int(($1.actualDuration ?? $1.duration) / 60) }
        let sessionCount = sessions.count
        let completedCount = sessions.filter(\.wasCompleted).count

        defaults?.set(totalMinutes, forKey: "widget_focus_minutes")
        defaults?.set(sessionCount, forKey: "widget_focus_sessions")
        defaults?.set(completedCount, forKey: "widget_focus_completed")
    }

    func updateScoreData(context: ModelContext) {
        let taskDesc = FetchDescriptor<TaskItem>(predicate: #Predicate { !$0.isTemplate })
        let totalTasks = (try? context.fetchCount(taskDesc)) ?? 0
        let completedDesc = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.isCompleted && !$0.isTemplate })
        let completedTasks = (try? context.fetchCount(completedDesc)) ?? 0

        let habitDesc = FetchDescriptor<Habit>(predicate: #Predicate { !$0.isArchived })
        let habits = (try? context.fetch(habitDesc)) ?? []
        let habitsCompleted = habits.filter(\.isCompletedToday).count

        let today = Calendar.current.startOfDay(for: .now)
        let focusDesc = FetchDescriptor<FocusSession>(predicate: #Predicate { $0.createdAt >= today })
        let focusMinutes = ((try? context.fetch(focusDesc)) ?? []).reduce(0) { $0 + Int(($1.actualDuration ?? $1.duration) / 60) }

        let score = DailyScore.calculateScore(
            tasksCompleted: completedTasks,
            tasksTotal: totalTasks,
            habitsCompleted: habitsCompleted,
            habitsTotal: habits.count,
            focusMinutes: focusMinutes
        )

        defaults?.set(Int(score), forKey: "widget_score_value")
    }
}
