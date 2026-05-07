import SwiftUI

#if os(iOS)
import UIKit

// MARK: - Quick Actions (Home Screen Shortcuts)

enum QuickAction: String {
    case newTask = "com.solderg.flo.newTask"
    case startFocus = "com.solderg.flo.startFocus"
    case viewHabits = "com.solderg.flo.viewHabits"
    case aiAssistant = "com.solderg.flo.aiAssistant"

    var shortcutItem: UIApplicationShortcutItem {
        switch self {
        case .newTask:
            return UIApplicationShortcutItem(
                type: rawValue,
                localizedTitle: "New Task",
                localizedSubtitle: "Add a task quickly",
                icon: UIApplicationShortcutIcon(systemImageName: "plus.circle.fill")
            )
        case .startFocus:
            return UIApplicationShortcutItem(
                type: rawValue,
                localizedTitle: "Start Focus",
                localizedSubtitle: "Begin a focus session",
                icon: UIApplicationShortcutIcon(systemImageName: "timer")
            )
        case .viewHabits:
            return UIApplicationShortcutItem(
                type: rawValue,
                localizedTitle: "Habits",
                localizedSubtitle: "Check today's habits",
                icon: UIApplicationShortcutIcon(systemImageName: "flame.fill")
            )
        case .aiAssistant:
            return UIApplicationShortcutItem(
                type: rawValue,
                localizedTitle: "AI Assistant",
                localizedSubtitle: "Ask Flo anything",
                icon: UIApplicationShortcutIcon(systemImageName: "sparkles")
            )
        }
    }

    @MainActor
    static func registerAll() {
        UIApplication.shared.shortcutItems = [
            QuickAction.newTask.shortcutItem,
            QuickAction.startFocus.shortcutItem,
            QuickAction.viewHabits.shortcutItem,
            QuickAction.aiAssistant.shortcutItem,
        ]
    }
}

// MARK: - Observable Quick Action State

@MainActor @Observable
final class QuickActionService {
    static let shared = QuickActionService()
    var pendingAction: QuickAction?

    func handle(_ shortcutItem: UIApplicationShortcutItem) {
        pendingAction = QuickAction(rawValue: shortcutItem.type)
    }
}
#endif
