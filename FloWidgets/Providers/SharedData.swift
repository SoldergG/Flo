import Foundation
import WidgetKit

// MARK: - App Group

enum FloAppGroup {
    static let suiteName = "group.com.solderg.flo"

    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
}

// MARK: - Widget Data Structures

struct WidgetTaskData: Codable, Identifiable {
    let id: String
    let title: String
    let isCompleted: Bool
    let priorityRaw: Int  // 1=high, 2=medium, 3=low
    let dueDate: Date?
    let scheduledDate: Date?
    let projectName: String?
    let projectColorHex: String?

    var priorityColor: String {
        switch priorityRaw {
        case 1: return "D94F4F"
        case 2: return "E5A84B"
        case 3: return "5BA37C"
        default: return "E5A84B"
        }
    }
}

struct WidgetHabitData: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let isCompletedToday: Bool
    let currentStreak: Int
    let bestStreak: Int
}

struct WidgetFocusData: Codable {
    let isActive: Bool
    let totalDuration: TimeInterval
    let elapsed: TimeInterval
    let taskTitle: String?
    let todayMinutes: Int

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return min(elapsed / totalDuration, 1.0)
    }

    var remainingSeconds: Int {
        max(0, Int(totalDuration - elapsed))
    }

    var remainingFormatted: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct WidgetScoreData: Codable {
    let score: Int              // 0-100
    let tasksCompleted: Int
    let tasksTotal: Int
    let habitsCompleted: Int
    let habitsTotal: Int
    let focusMinutes: Int
}

// MARK: - UserDefaults Keys

enum WidgetDataKeys {
    static let tasks = "widget_tasks"
    static let habits = "widget_habits"
    static let focus = "widget_focus"
    static let score = "widget_score"
    static let lastUpdated = "widget_last_updated"
}

// MARK: - Widget Data Provider

struct WidgetDataProvider {

    // MARK: - Read

    static func loadTasks() -> [WidgetTaskData] {
        guard let data = FloAppGroup.userDefaults.data(forKey: WidgetDataKeys.tasks),
              let tasks = try? JSONDecoder().decode([WidgetTaskData].self, from: data) else {
            return []
        }
        return tasks
    }

    static func loadHabits() -> [WidgetHabitData] {
        guard let data = FloAppGroup.userDefaults.data(forKey: WidgetDataKeys.habits),
              let habits = try? JSONDecoder().decode([WidgetHabitData].self, from: data) else {
            return []
        }
        return habits
    }

    static func loadFocus() -> WidgetFocusData {
        guard let data = FloAppGroup.userDefaults.data(forKey: WidgetDataKeys.focus),
              let focus = try? JSONDecoder().decode(WidgetFocusData.self, from: data) else {
            return WidgetFocusData(
                isActive: false,
                totalDuration: 0,
                elapsed: 0,
                taskTitle: nil,
                todayMinutes: 0
            )
        }
        return focus
    }

    static func loadScore() -> WidgetScoreData {
        guard let data = FloAppGroup.userDefaults.data(forKey: WidgetDataKeys.score),
              let score = try? JSONDecoder().decode(WidgetScoreData.self, from: data) else {
            return WidgetScoreData(
                score: 0,
                tasksCompleted: 0,
                tasksTotal: 0,
                habitsCompleted: 0,
                habitsTotal: 0,
                focusMinutes: 0
            )
        }
        return score
    }

    // MARK: - Write (called from the main app)

    static func saveTasks(_ tasks: [WidgetTaskData]) {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        FloAppGroup.userDefaults.set(data, forKey: WidgetDataKeys.tasks)
        FloAppGroup.userDefaults.set(Date(), forKey: WidgetDataKeys.lastUpdated)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func saveHabits(_ habits: [WidgetHabitData]) {
        guard let data = try? JSONEncoder().encode(habits) else { return }
        FloAppGroup.userDefaults.set(data, forKey: WidgetDataKeys.habits)
        FloAppGroup.userDefaults.set(Date(), forKey: WidgetDataKeys.lastUpdated)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func saveFocus(_ focus: WidgetFocusData) {
        guard let data = try? JSONEncoder().encode(focus) else { return }
        FloAppGroup.userDefaults.set(data, forKey: WidgetDataKeys.focus)
        FloAppGroup.userDefaults.set(Date(), forKey: WidgetDataKeys.lastUpdated)
        WidgetCenter.shared.reloadTimelines(ofKind: "FocusTimerWidget")
    }

    static func saveScore(_ score: WidgetScoreData) {
        guard let data = try? JSONEncoder().encode(score) else { return }
        FloAppGroup.userDefaults.set(data, forKey: WidgetDataKeys.score)
        FloAppGroup.userDefaults.set(Date(), forKey: WidgetDataKeys.lastUpdated)
        WidgetCenter.shared.reloadTimelines(ofKind: "ProductivityScoreWidget")
    }

    // MARK: - Habit Toggle (used by widget intent)

    static func toggleHabit(id: String) {
        var habits = loadHabits()
        guard let index = habits.firstIndex(where: { $0.id == id }) else { return }
        let habit = habits[index]
        habits[index] = WidgetHabitData(
            id: habit.id,
            name: habit.name,
            icon: habit.icon,
            isCompletedToday: !habit.isCompletedToday,
            currentStreak: habit.isCompletedToday ? max(0, habit.currentStreak - 1) : habit.currentStreak + 1,
            bestStreak: habit.bestStreak
        )
        guard let data = try? JSONEncoder().encode(habits) else { return }
        FloAppGroup.userDefaults.set(data, forKey: WidgetDataKeys.habits)

        // Flag for main app to sync
        FloAppGroup.userDefaults.set(id, forKey: "widget_toggled_habit_id")
        FloAppGroup.userDefaults.set(!habit.isCompletedToday, forKey: "widget_toggled_habit_value")

        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Snapshot Data (for previews)

    static var snapshotTasks: [WidgetTaskData] {
        [
            WidgetTaskData(id: "1", title: "Review design mockups", isCompleted: false, priorityRaw: 1, dueDate: Date().addingTimeInterval(3600), scheduledDate: nil, projectName: "App Redesign", projectColorHex: "D97757"),
            WidgetTaskData(id: "2", title: "Write unit tests", isCompleted: false, priorityRaw: 2, dueDate: Date().addingTimeInterval(7200), scheduledDate: nil, projectName: "Backend", projectColorHex: "5BA37C"),
            WidgetTaskData(id: "3", title: "Team standup", isCompleted: true, priorityRaw: 2, dueDate: nil, scheduledDate: nil, projectName: nil, projectColorHex: nil),
        ]
    }

    static var snapshotHabits: [WidgetHabitData] {
        [
            WidgetHabitData(id: "1", name: "Meditate", icon: "brain.head.profile", isCompletedToday: true, currentStreak: 12, bestStreak: 30),
            WidgetHabitData(id: "2", name: "Exercise", icon: "figure.run", isCompletedToday: true, currentStreak: 5, bestStreak: 14),
            WidgetHabitData(id: "3", name: "Read", icon: "book.fill", isCompletedToday: false, currentStreak: 8, bestStreak: 21),
            WidgetHabitData(id: "4", name: "Journal", icon: "pencil.line", isCompletedToday: false, currentStreak: 0, bestStreak: 7),
        ]
    }

    static var snapshotFocus: WidgetFocusData {
        WidgetFocusData(
            isActive: true,
            totalDuration: 1500,
            elapsed: 600,
            taskTitle: "Review design mockups",
            todayMinutes: 85
        )
    }

    static var snapshotScore: WidgetScoreData {
        WidgetScoreData(
            score: 73,
            tasksCompleted: 5,
            tasksTotal: 8,
            habitsCompleted: 3,
            habitsTotal: 4,
            focusMinutes: 85
        )
    }
}
