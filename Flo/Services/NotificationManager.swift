import Foundation
import UserNotifications

// MARK: - Notification Manager

@MainActor
enum NotificationManager {
    // MARK: - Permission

    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - Habit Reminders

    static func scheduleHabitReminder(habitName: String, time: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = "Time to work on: \(habitName)"
        content.sound = .default
        content.categoryIdentifier = "HABIT_REMINDER"

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "habit-\(identifier)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Focus Session Complete

    static func scheduleFocusComplete(after seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Focus Complete!"
        content.body = "Great work! You completed your focus session."
        content.sound = .default
        content.categoryIdentifier = "FOCUS_COMPLETE"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "focus-complete", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Morning Check-in

    static func scheduleMorningReminder(hour: Int = 8, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Good Morning!"
        content.body = "Start your day with a quick check-in and plan ahead."
        content.sound = .default
        content.categoryIdentifier = "MORNING_CHECKIN"

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "morning-checkin", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Evening Review

    static func scheduleEveningReminder(hour: Int = 21, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Evening Review"
        content.body = "Take a moment to reflect on your day and plan tomorrow."
        content.sound = .default
        content.categoryIdentifier = "EVENING_REVIEW"

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "evening-review", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Task Due Reminder

    static func scheduleTaskDueReminder(taskTitle: String, dueDate: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "Task Due Soon"
        content.body = "\(taskTitle) is due today"
        content.sound = .default
        content.categoryIdentifier = "TASK_DUE"

        let reminderDate = Calendar.current.date(byAdding: .hour, value: -1, to: dueDate) ?? dueDate
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "task-\(identifier)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel

    static func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
