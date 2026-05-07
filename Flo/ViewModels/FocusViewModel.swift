import Foundation
import SwiftData
import SwiftUI
import UserNotifications
#if os(iOS)
import AudioToolbox
#endif

// MARK: - Focus Phase

enum FocusPhase: Equatable {
    case work, breakTime, idle
}

// MARK: - FocusViewModel

@MainActor @Observable
final class FocusViewModel {

    // MARK: - Editable durations
    var workMinutes: Int = 25 {
        didSet { workMinutes = max(1, min(120, workMinutes)) }
    }
    var breakMinutes: Int = 5 {
        didSet { breakMinutes = max(1, min(60, breakMinutes)) }
    }

    // MARK: - State
    var phase: FocusPhase = .idle
    var isRunning = false
    var isPaused = false
    var timeRemaining: TimeInterval = 0
    var selectedTask: TaskItem?
    var showCompleted = false
    var showBreakCompleted = false
    var sessionsToday = 0

    private var timer: Timer?
    private var tickCount = 0

    // MARK: - Computed

    var totalDuration: TimeInterval {
        phase == .breakTime
            ? TimeInterval(breakMinutes * 60)
            : TimeInterval(workMinutes * 60)
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalDuration)
    }

    var formattedTime: String {
        let m = Int(timeRemaining) / 60
        let s = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", m, s)
    }

    // Legacy compatibility
    var selectedDuration: FocusDuration {
        FocusDuration.allCases.min(by: {
            abs($0.rawValue - workMinutes) < abs($1.rawValue - workMinutes)
        }) ?? .medium
    }

    // MARK: - Actions

    func startSession() {
        phase = .work
        timeRemaining = TimeInterval(workMinutes * 60)
        isRunning = true
        isPaused = false
        tickCount = 0
        scheduleNotification(seconds: workMinutes * 60, body: "Focus session complete! Time for a break.")
        LiveActivityManager.startFocusActivity(duration: TimeInterval(workMinutes * 60), taskName: selectedTask?.title ?? "")
        startTimer()
    }

    func startBreak() {
        showCompleted = false
        phase = .breakTime
        timeRemaining = TimeInterval(breakMinutes * 60)
        isRunning = true
        isPaused = false
        tickCount = 0
        scheduleNotification(seconds: breakMinutes * 60, body: "Break over! Ready to focus again?")
        LiveActivityManager.startFocusActivity(duration: TimeInterval(breakMinutes * 60), taskName: "Break")
        startTimer()
    }

    func pauseSession() {
        isPaused = true
        timer?.invalidate(); timer = nil
        cancelNotification()
        LiveActivityManager.updateFocusActivity(timeRemaining: timeRemaining, totalDuration: totalDuration, isPaused: true)
    }

    func resumeSession() {
        isPaused = false
        let body = phase == .breakTime ? "Break over! Ready to focus again?" : "Focus session complete! Time for a break."
        scheduleNotification(seconds: Int(timeRemaining), body: body)
        startTimer()
        LiveActivityManager.updateFocusActivity(timeRemaining: timeRemaining, totalDuration: totalDuration, isPaused: false)
    }

    func stopSession(context: ModelContext) {
        timer?.invalidate(); timer = nil
        cancelNotification()
        if phase == .work {
            let session = FocusSession(duration: TimeInterval(workMinutes * 60), task: selectedTask)
            session.actualDuration = TimeInterval(workMinutes * 60) - timeRemaining
            session.wasCompleted = timeRemaining <= 0
            context.insert(session)
            try? context.save()
            sessionsToday += 1
        }
        LiveActivityManager.endFocusActivity()
        phase = .idle; isRunning = false; isPaused = false; timeRemaining = 0
    }

    func resetSession() {
        timer?.invalidate(); timer = nil
        cancelNotification()
        LiveActivityManager.endFocusActivity()
        phase = .idle; isRunning = false; isPaused = false; timeRemaining = 0
    }

    func loadTodaySessions(context: ModelContext) {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<FocusSession>(predicate: #Predicate { $0.createdAt >= startOfDay })
        sessionsToday = (try? context.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    self.tickCount += 1
                    if self.tickCount % 5 == 0 {
                        LiveActivityManager.updateFocusActivity(timeRemaining: self.timeRemaining, totalDuration: self.totalDuration, isPaused: false)
                    }
                } else {
                    self.timer?.invalidate(); self.timer = nil
                    self.handleSessionEnd()
                }
            }
        }
    }

    private func handleSessionEnd() {
        playSound()
        LiveActivityManager.endFocusActivity()
        if phase == .work {
            showCompleted = true
        } else {
            showBreakCompleted = true
            phase = .idle; isRunning = false
        }
    }

    // MARK: - Notifications

    private func scheduleNotification(seconds: Int, body: String) {
        Task {
            let center = UNUserNotificationCenter.current()
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            center.removePendingNotificationRequests(withIdentifiers: ["focus-complete"])
            let content = UNMutableNotificationContent()
            content.title = "Flo"
            content.body = body
            content.sound = .defaultCritical
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, TimeInterval(seconds)), repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "focus-complete", content: content, trigger: trigger))
        }
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["focus-complete"])
    }

    // MARK: - Sound

    private func playSound() {
        #if os(iOS)
        AudioServicesPlaySystemSound(1007)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        #endif
    }
}
