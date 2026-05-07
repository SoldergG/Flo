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
    var label: String { "\(rawValue) min" }
    var seconds: TimeInterval { TimeInterval(rawValue * 60) }
}

// MARK: - Kanban Status

enum KanbanStatus: String, CaseIterable, Identifiable {
    case todo = "todo"
    case inProgress = "in_progress"
    case done = "done"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .todo: "To Do"
        case .inProgress: "In Progress"
        case .done: "Done"
        }
    }

    var icon: String {
        switch self {
        case .todo: "circle"
        case .inProgress: "arrow.right.circle.fill"
        case .done: "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .todo: FloColors.Hex.textSecondary
        case .inProgress: FloColors.Hex.warning
        case .done: FloColors.Hex.success
        }
    }
}

// MARK: - Ambient Sound

enum AmbientSound: String, CaseIterable, Identifiable {
    case rain
    case ocean
    case forest
    case cafe
    case fireplace
    case whiteNoise
    case lofi
    case thunder

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rain: "Rain"
        case .ocean: "Ocean"
        case .forest: "Forest"
        case .cafe: "Café"
        case .fireplace: "Fireplace"
        case .whiteNoise: "White Noise"
        case .lofi: "Lo-Fi"
        case .thunder: "Thunder"
        }
    }

    var icon: String {
        switch self {
        case .rain: "cloud.rain.fill"
        case .ocean: "water.waves"
        case .forest: "leaf.fill"
        case .cafe: "cup.and.saucer.fill"
        case .fireplace: "flame.fill"
        case .whiteNoise: "waveform"
        case .lofi: "headphones"
        case .thunder: "cloud.bolt.fill"
        }
    }
}

// MARK: - Habit Category

enum HabitCategory: String, CaseIterable, Identifiable {
    case health
    case mind
    case productivity
    case social
    case creativity
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .health: "Health"
        case .mind: "Mind"
        case .productivity: "Productivity"
        case .social: "Social"
        case .creativity: "Creativity"
        case .custom: "Custom"
        }
    }

    var icon: String {
        switch self {
        case .health: "heart.fill"
        case .mind: "brain.head.profile.fill"
        case .productivity: "bolt.fill"
        case .social: "person.2.fill"
        case .creativity: "paintbrush.fill"
        case .custom: "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .health: FloColors.Hex.error
        case .mind: Color(hex: "8B5CF6")
        case .productivity: FloColors.Hex.accent
        case .social: Color(hex: "4A90D9")
        case .creativity: Color(hex: "EC4899")
        case .custom: FloColors.Hex.warning
        }
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

// MARK: - Eisenhower Quadrant

enum EisenhowerQuadrant: Int, CaseIterable, Identifiable {
    case doFirst = 1
    case schedule = 2
    case delegate = 3
    case eliminate = 4

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .doFirst: "Do First"
        case .schedule: "Schedule"
        case .delegate: "Delegate"
        case .eliminate: "Eliminate"
        }
    }

    var subtitle: String {
        switch self {
        case .doFirst: "Urgent & Important"
        case .schedule: "Not Urgent & Important"
        case .delegate: "Urgent & Not Important"
        case .eliminate: "Neither"
        }
    }

    var color: Color {
        switch self {
        case .doFirst: FloColors.Hex.error
        case .schedule: Color(hex: "4A90D9")
        case .delegate: FloColors.Hex.warning
        case .eliminate: FloColors.Hex.textTertiary
        }
    }

    var icon: String {
        switch self {
        case .doFirst: "exclamationmark.2"
        case .schedule: "calendar.badge.clock"
        case .delegate: "person.badge.clock"
        case .eliminate: "xmark.circle"
        }
    }
}
