import Foundation
import SwiftData
import SwiftUI
import Combine

@Observable
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
    }

    func pauseSession() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    func resumeSession() {
        isPaused = false
        startTimer()
    }

    func stopSession(context: ModelContext) {
        timer?.invalidate()
        timer = nil

        let session = FocusSession(duration: selectedDuration.seconds, task: selectedTask)
        session.actualDuration = selectedDuration.seconds - timeRemaining
        session.wasCompleted = timeRemaining <= 0
        context.insert(session)
        try? context.save()

        isRunning = false
        isPaused = false
        timeRemaining = 0
        sessionsToday += 1

        if timeRemaining <= 0 {
            showCompleted = true
        }
    }

    func resetSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        timeRemaining = 0
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timer?.invalidate()
                self.timer = nil
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
