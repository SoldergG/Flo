import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor @Observable
final class FocusViewModel {
    var selectedDuration: FocusDuration = .medium
    var isRunning = false
    var isPaused = false
    var timeRemaining: TimeInterval = 0
    var selectedTask: TaskItem?
    var showCompleted = false
    var sessionsToday = 0

    private var timer: Timer?
    private var sessionStartDate: Date?

    var progress: Double {
        guard selectedDuration.seconds > 0 else { return 0 }
        return 1.0 - (timeRemaining / selectedDuration.seconds)
    }

    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func startSession() {
        timeRemaining = selectedDuration.seconds
        sessionStartDate = .now
        isRunning = true
        isPaused = false
        startTimer()

        // Start Live Activity
        LiveActivityManager.startFocusActivity(
            duration: selectedDuration.seconds,
            taskName: selectedTask?.title ?? ""
        )
    }

    func pauseSession() {
        isPaused = true
        timer?.invalidate()
        timer = nil

        LiveActivityManager.updateFocusActivity(
            timeRemaining: timeRemaining,
            totalDuration: selectedDuration.seconds,
            isPaused: true
        )
    }

    func resumeSession() {
        isPaused = false
        startTimer()

        LiveActivityManager.updateFocusActivity(
            timeRemaining: timeRemaining,
            totalDuration: selectedDuration.seconds,
            isPaused: false
        )
    }

    func stopSession(context: ModelContext) {
        timer?.invalidate()
        timer = nil

        let session = FocusSession(duration: selectedDuration.seconds, task: selectedTask)
        session.actualDuration = selectedDuration.seconds - timeRemaining
        let completed = timeRemaining <= 0
        session.wasCompleted = completed
        context.insert(session)
        try? context.save()

        isRunning = false
        isPaused = false
        timeRemaining = 0
        sessionsToday += 1

        // End Live Activity
        LiveActivityManager.endFocusActivity()

        if completed {
            showCompleted = true
        }
    }

    func resetSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        timeRemaining = 0

        // End Live Activity
        LiveActivityManager.endFocusActivity()
    }

    private var tickCount = 0

    private func startTimer() {
        tickCount = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    self.tickCount += 1

                    // Update Live Activity every 5 seconds
                    if self.tickCount % 5 == 0 {
                        LiveActivityManager.updateFocusActivity(
                            timeRemaining: self.timeRemaining,
                            totalDuration: self.selectedDuration.seconds,
                            isPaused: false
                        )
                    }
                } else {
                    self.timer?.invalidate()
                    self.timer = nil
                }
            }
        }
    }

    func loadTodaySessions(context: ModelContext) {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.createdAt >= startOfDay }
        )
        sessionsToday = (try? context.fetchCount(descriptor)) ?? 0
    }
}
