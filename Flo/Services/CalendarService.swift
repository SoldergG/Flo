import Foundation
import EventKit
import UserNotifications

// MARK: - Calendar Service

@MainActor
enum CalendarService {
    private static let eventStore = EKEventStore()

    // MARK: - Authorization

    static func requestAccess() async -> Bool {
        if #available(iOS 17.0, macOS 14.0, *) {
            do {
                return try await eventStore.requestFullAccessToEvents()
            } catch {
                return false
            }
        } else {
            do {
                return try await eventStore.requestAccess(to: .event)
            } catch {
                return false
            }
        }
    }

    static var hasAccess: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        return status == .fullAccess
    }

    // MARK: - Create Recurring Habit Event

    @discardableResult
    static func createHabitEvent(
        name: String,
        icon: String,
        reminderTime: Date,
        frequency: String
    ) async -> String? {
        let granted = await requestAccess()
        guard granted else { return nil }

        let event = EKEvent(eventStore: eventStore)
        event.title = "\(name)"
        event.notes = "Flo Habit Reminder"
        event.calendar = eventStore.defaultCalendarForNewEvents

        // Set the event for today at the reminder time
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        var startComponents = calendar.dateComponents([.year, .month, .day], from: .now)
        startComponents.hour = timeComponents.hour
        startComponents.minute = timeComponents.minute

        guard let startDate = calendar.date(from: startComponents) else { return nil }
        event.startDate = startDate
        event.endDate = calendar.date(byAdding: .minute, value: 30, to: startDate)

        // Add alarm 5 minutes before
        event.addAlarm(EKAlarm(relativeOffset: -300))

        // Set recurrence based on frequency
        let recurrenceRule: EKRecurrenceRule?
        switch frequency {
        case "daily":
            recurrenceRule = EKRecurrenceRule(
                recurrenceWith: .daily,
                interval: 1,
                end: nil
            )
        case "weekdays":
            let weekdays = [
                EKRecurrenceDayOfWeek(.monday),
                EKRecurrenceDayOfWeek(.tuesday),
                EKRecurrenceDayOfWeek(.wednesday),
                EKRecurrenceDayOfWeek(.thursday),
                EKRecurrenceDayOfWeek(.friday)
            ]
            recurrenceRule = EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 1,
                daysOfTheWeek: weekdays,
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: nil
            )
        case "weekends":
            let weekendDays = [
                EKRecurrenceDayOfWeek(.saturday),
                EKRecurrenceDayOfWeek(.sunday)
            ]
            recurrenceRule = EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 1,
                daysOfTheWeek: weekendDays,
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: nil
            )
        default:
            recurrenceRule = EKRecurrenceRule(
                recurrenceWith: .daily,
                interval: 1,
                end: nil
            )
        }

        if let rule = recurrenceRule {
            event.addRecurrenceRule(rule)
        }

        do {
            try eventStore.save(event, span: .futureEvents)
            return event.eventIdentifier
        } catch {
            return nil
        }
    }

    // MARK: - Remove Habit Event

    static func removeHabitEvent(identifier: String) {
        guard hasAccess else { return }
        guard let event = eventStore.event(withIdentifier: identifier) else { return }
        try? eventStore.remove(event, span: .futureEvents)
    }

    // MARK: - Schedule Local Notification for Habit

    static func scheduleHabitReminder(name: String, time: Date, habitId: String) {
        Task {
            let center = UNUserNotificationCenter.current()
            _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])

            // Remove old notification
            center.removePendingNotificationRequests(withIdentifiers: [habitId])

            let content = UNMutableNotificationContent()
            content.title = "Habit Reminder"
            content.body = "Time to complete: \(name)"
            content.sound = .default
            content.categoryIdentifier = "HABIT_REMINDER"

            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let request = UNNotificationRequest(
                identifier: habitId,
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }
}
