import Foundation
import SwiftUI

// MARK: - Priority

enum Priority: Int, Codable, CaseIterable, Identifiable {
    case high = 1
    case medium = 2
    case low = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .high: "High"
        case .medium: "Medium"
        case .low: "Low"
        }
    }

    var icon: String {
        switch self {
        case .high: "exclamationmark.circle.fill"
        case .medium: "minus.circle.fill"
        case .low: "arrow.down.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .high: FloColors.Hex.priorityHigh
        case .medium: FloColors.Hex.priorityMedium
        case .low: FloColors.Hex.priorityLow
        }
    }
}

// MARK: - Recurrence

enum Recurrence: String, Codable, CaseIterable {
    case daily
    case weekdays
    case weekly
    case biweekly
    case monthly

    var label: String {
        switch self {
        case .daily: "Daily"
        case .weekdays: "Weekdays"
        case .weekly: "Weekly"
        case .biweekly: "Bi-weekly"
        case .monthly: "Monthly"
        }
    }
}

// MARK: - Frequency (Habits)

enum Frequency: String, Codable, CaseIterable {
    case daily
    case weekdays
    case weekends
    case custom

    var label: String {
        switch self {
        case .daily: "Every day"
        case .weekdays: "Weekdays"
        case .weekends: "Weekends"
        case .custom: "Custom"
        }
    }
}

// MARK: - Focus Duration

enum FocusDuration: Int, CaseIterable, Identifiable {
    case short = 15
    case medium = 25
    case long = 50
    case deep = 90

    var id: Int { rawValue }

    var label: String {
        "\(rawValue) min"
    }

    var seconds: TimeInterval {
        TimeInterval(rawValue * 60)
    }
}

// MARK: - App Tab

enum AppTab: String, CaseIterable, Identifiable {
    case planner
    case tasks
    case focus
    case habits
    case notes

    var id: String { rawValue }

    var label: String {
        switch self {
        case .planner: "Today"
        case .tasks: "Tasks"
        case .focus: "Focus"
        case .habits: "Habits"
        case .notes: "Notes"
        }
    }

    var icon: String {
        switch self {
        case .planner: "calendar"
        case .tasks: "checkmark.circle"
        case .focus: "timer"
        case .habits: "flame"
        case .notes: "note.text"
        }
    }

    var selectedIcon: String {
        switch self {
        case .planner: "calendar"
        case .tasks: "checkmark.circle.fill"
        case .focus: "timer"
        case .habits: "flame.fill"
        case .notes: "note.text"
        }
    }
}
