import SwiftUI
import SwiftData

// MARK: - Productivity Score View (FIX #30: real score computed from actual data)

struct ProductivityScoreView: View {
    @Query private var allTasks: [TaskItem]
    @Query private var habits: [Habit]
    @Query private var focusSessions: [FocusSession]
    @Query private var moodEntries: [MoodEntry]

    @State private var animatedScore: Double = 0

    // FIX #31: weighted real score
    private var score: Int {
        var points = 0.0

        // Tasks (40 pts): completion rate of today's tasks
        let today = Calendar.current.startOfDay(for: .now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let todayTasks = allTasks.filter {
            guard !$0.isTemplate else { return false }
            if let d = $0.dueDate { return d >= today && d < tomorrow }
            if let d = $0.scheduledDate { return d >= today && d < tomorrow }
            return $0.isCompleted && ($0.completedAt ?? $0.createdAt) >= today
        }
        if !todayTasks.isEmpty {
            let completed = todayTasks.filter(\.isCompleted).count
            points += Double(completed) / Double(todayTasks.count) * 40
        } else {
            points += 20 // neutral if no tasks scheduled
        }

        // Habits (35 pts): today's completion rate
        let activeHabits = habits.filter { !$0.isArchived }
        if !activeHabits.isEmpty {
            let completed = activeHabits.filter(\.isCompletedToday).count
            points += Double(completed) / Double(activeHabits.count) * 35
        } else {
            points += 17
        }

        // Focus (25 pts): ≥90 min = full score
        let todayFocusSeconds = focusSessions.filter { $0.startedAt >= today }.reduce(0) { $0 + ($1.actualDuration ?? $1.duration) }
        let focusMinutes = todayFocusSeconds / 60
        points += min(25, focusMinutes / 90 * 25)

        return max(0, min(100, Int(points)))
    }

    private var scoreColor: Color {
        switch score {
        case 80...100: return FloColors.Hex.success
        case 50..<80: return FloColors.Hex.warning
        default: return FloColors.Hex.error
        }
    }

    private var scoreLabel: String {
        switch score {
        case 90...100: return "Outstanding! 🚀"
        case 75..<90: return "Great work! 💪"
        case 60..<75: return "Good progress 👍"
        case 40..<60: return "Keep going! ✨"
        default: return "Just getting started"
        }
    }

    var body: some View {
        ZStack {
            FloColors.Hex.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Score ring
                    ZStack {
                        Circle()
                            .stroke(FloColors.Hex.border.opacity(0.2), lineWidth: 16)
                            .frame(width: 200, height: 200)

                        Circle()
                            .trim(from: 0, to: animatedScore / 100)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.2), value: animatedScore)

                        VStack(spacing: 6) {
                            Text("\(Int(animatedScore))")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(FloColors.Hex.textPrimary)
                                .contentTransition(.numericText())
                            Text("Today")
                                .font(FloTypography.caption)
                                .foregroundStyle(FloColors.Hex.textSecondary)
                        }
                    }

                    Text(scoreLabel)
                        .font(FloTypography.title3)
                        .foregroundStyle(FloColors.Hex.textPrimary)

                    // Breakdown (FIX #32: show score components)
                    VStack(spacing: 12) {
                        scoreBreakdownRow(
                            icon: "checkmark.circle.fill",
                            label: "Tasks",
                            color: FloColors.Hex.accent,
                            maxPts: 40,
                            description: taskBreakdownText
                        )
                        scoreBreakdownRow(
                            icon: "flame.fill",
                            label: "Habits",
                            color: FloColors.Hex.warning,
                            maxPts: 35,
                            description: habitBreakdownText
                        )
                        scoreBreakdownRow(
                            icon: "timer",
                            label: "Focus",
                            color: FloColors.Hex.success,
                            maxPts: 25,
                            description: focusBreakdownText
                        )
                    }
                    .padding(.horizontal, 20)

                    // Tips based on score
                    if score < 80 {
                        FloCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Boost your score", systemImage: "lightbulb.fill")
                                    .font(FloTypography.headline)
                                    .foregroundStyle(FloColors.Hex.textPrimary)
                                ForEach(scoreTips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 8) {
                                        Circle().fill(FloColors.Hex.accent).frame(width: 5, height: 5).offset(y: 6)
                                        Text(tip)
                                            .font(FloTypography.body)
                                            .foregroundStyle(FloColors.Hex.textSecondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 24)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Productivity Score")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animatedScore = Double(score)
            }
        }
    }

    private func scoreBreakdownRow(icon: String, label: String, color: Color, maxPts: Int, description: String) -> some View {
        FloCard {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                    Text(description)
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
                Spacer()
                Text("/ \(maxPts)pts")
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textTertiary)
            }
        }
    }

    // MARK: - Breakdown Texts

    private var taskBreakdownText: String {
        let today = Calendar.current.startOfDay(for: .now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let todayTasks = allTasks.filter {
            guard !$0.isTemplate else { return false }
            if let d = $0.dueDate { return d >= today && d < tomorrow }
            if let d = $0.scheduledDate { return d >= today && d < tomorrow }
            return $0.isCompleted && ($0.completedAt ?? $0.createdAt) >= today
        }
        if todayTasks.isEmpty { return "No tasks scheduled today" }
        let done = todayTasks.filter(\.isCompleted).count
        return "\(done) of \(todayTasks.count) completed"
    }

    private var habitBreakdownText: String {
        let active = habits.filter { !$0.isArchived }
        if active.isEmpty { return "No habits yet" }
        let done = active.filter(\.isCompletedToday).count
        return "\(done) of \(active.count) done today"
    }

    private var focusBreakdownText: String {
        let today = Calendar.current.startOfDay(for: .now)
        let seconds = focusSessions.filter { $0.startedAt >= today }.reduce(0) { $0 + ($1.actualDuration ?? $1.duration) }
        let minutes = Int(seconds / 60)
        return minutes > 0 ? "\(minutes) min focused (goal: 90)" : "No focus sessions today"
    }

    private var scoreTips: [String] {
        var tips: [String] = []
        let today = Calendar.current.startOfDay(for: .now)
        let active = habits.filter { !$0.isArchived }
        let remaining = active.filter { !$0.isCompletedToday }.count
        if remaining > 0 { tips.append("Complete \(remaining) more habit\(remaining == 1 ? "" : "s") to earn habit points") }
        let focusSec = focusSessions.filter { $0.startedAt >= today }.reduce(0) { $0 + ($1.actualDuration ?? $1.duration) }
        if focusSec < 5400 { tips.append("Add a focus session to boost your score (goal: 90 min)") }
        if tips.isEmpty { tips.append("Complete your scheduled tasks to reach 100") }
        return tips
    }
}
