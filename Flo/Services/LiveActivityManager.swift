import Foundation

#if canImport(ActivityKit)
import ActivityKit

// MARK: - Live Activity Manager

@MainActor
enum LiveActivityManager {
    private nonisolated(unsafe) static var currentActivityID: String?

    // MARK: - Start Focus Activity

    static func startFocusActivity(
        duration: TimeInterval,
        taskName: String = ""
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // End any existing activity
        endFocusActivity()

        let attributes = FocusActivityAttributes(
            taskName: taskName,
            totalDuration: duration,
            startedAt: .now
        )

        let state = FocusActivityAttributes.ContentState(
            timeRemaining: duration,
            progress: 0,
            isPaused: false
        )

        do {
            let content = ActivityContent(state: state, staleDate: nil)
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivityID = activity.id
        } catch {
            // Live Activity not available
        }
    }

    // MARK: - Update Focus Activity

    static func updateFocusActivity(
        timeRemaining: TimeInterval,
        totalDuration: TimeInterval,
        isPaused: Bool
    ) {
        guard let activityID = currentActivityID else { return }

        let progress = totalDuration > 0 ? 1.0 - (timeRemaining / totalDuration) : 0

        let state = FocusActivityAttributes.ContentState(
            timeRemaining: timeRemaining,
            progress: progress,
            isPaused: isPaused
        )

        Task.detached {
            let content = ActivityContent(state: state, staleDate: nil)
            for activity in Activity<FocusActivityAttributes>.activities where activity.id == activityID {
                await activity.update(content)
            }
        }
    }

    // MARK: - End Focus Activity

    static func endFocusActivity() {
        guard let activityID = currentActivityID else { return }

        let finalState = FocusActivityAttributes.ContentState(
            timeRemaining: 0,
            progress: 1.0,
            isPaused: false
        )

        Task.detached {
            let content = ActivityContent(state: finalState, staleDate: nil)
            for activity in Activity<FocusActivityAttributes>.activities where activity.id == activityID {
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }

        currentActivityID = nil
    }
}

#else

// MARK: - Stub for macOS

@MainActor
enum LiveActivityManager {
    static func startFocusActivity(duration: TimeInterval, taskName: String = "") {}
    static func updateFocusActivity(timeRemaining: TimeInterval, totalDuration: TimeInterval, isPaused: Bool) {}
    static func endFocusActivity() {}
}

#endif
