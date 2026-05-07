import SwiftUI
import SwiftData

// MARK: - Advanced Statistics Dashboard

struct AdvancedStatsView: View {
    @Query private var tasks: [TaskItem]
    @Query private var habits: [Habit]
    @Query private var focusSessions: [FocusSession]
    @Query private var moodEntries: [MoodEntry]

    @State private var selectedTimeframe: StatsTimeframe = .week

    enum StatsTimeframe: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case quarter = "90D"
        case year = "1Y"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Timeframe picker
                timeframePicker

                // Overview cards
                overviewGrid

                // Task completion trend
                completionTrendCard

                // Focus hours card
                focusHoursCard

                // Habit consistency card
                habitConsistencyCard

                // Mood overview card
                moodOverviewCard

                // Productivity insights
                insightsCard
            }
            .padding(16)
        }
        .background(FloColors.Hex.background)
        .navigationTitle("Statistics")
    }

    // MARK: - Timeframe Picker

    private var timeframePicker: some View {
        HStack(spacing: 4) {
            ForEach(StatsTimeframe.allCases, id: \.self) { timeframe in
                Button {
                    withAnimation(FloAnimations.springSnappy) {
                        selectedTimeframe = timeframe
                    }
                } label: {
                    Text(timeframe.rawValue)
                        .font(FloTypography.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedTimeframe == timeframe ? FloColors.Hex.accent : FloColors.Hex.surface)
                        .foregroundStyle(selectedTimeframe == timeframe ? .white : FloColors.Hex.textSecondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(FloColors.Hex.surface)
        .clipShape(Capsule())
    }

    // MARK: - Overview Grid

    private var overviewGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            FloStatCard(
                title: "Tasks Done",
                value: "\(completedTaskCount)",
                icon: "checkmark.circle.fill",
                color: FloColors.Hex.success
            )
            FloStatCard(
                title: "Focus Hours",
                value: String(format: "%.1f", totalFocusHours),
                icon: "timer",
                color: FloColors.Hex.accent
            )
            FloStatCard(
                title: "Habits Kept",
                value: "\(habitCompletionCount)",
                icon: "flame.fill",
                color: FloColors.Hex.warning
            )
            FloStatCard(
                title: "Best Streak",
                value: "\(bestOverallStreak)",
                icon: "bolt.fill",
                color: Color(hex: "8B5CF6")
            )
        }
    }

    // MARK: - Completion Trend

    private var completionTrendCard: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Task Completion")
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                    Spacer()
                    Text("\(completionRate)%")
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.success)
                }

                // Simple bar chart
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(dailyCompletionData, id: \.day) { data in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(data.count > 0 ? FloColors.Hex.success : FloColors.Hex.border)
                                .frame(height: max(4, CGFloat(data.count) * 12))

                            Text(data.label)
                                .font(.system(size: 8))
                                .foregroundStyle(FloColors.Hex.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 80)
            }
        }
    }

    // MARK: - Focus Hours

    private var focusHoursCard: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Focus Time")
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                    Spacer()
                    Text(String(format: "%.0fh %.0fm", totalFocusHours, (totalFocusHours.truncatingRemainder(dividingBy: 1)) * 60))
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.accent)
                }

                HStack(spacing: 16) {
                    StatPill(label: "Sessions", value: "\(filteredFocusSessions.count)", color: FloColors.Hex.accent)
                    StatPill(label: "Avg Length", value: String(format: "%.0fm", averageSessionLength), color: FloColors.Hex.accentSecondary)
                    StatPill(label: "Completed", value: "\(focusCompletionRate)%", color: FloColors.Hex.success)
                }
            }
        }
    }

    // MARK: - Habit Consistency

    private var habitConsistencyCard: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Habit Consistency")
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                if habits.isEmpty {
                    Text("No habits tracked yet")
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textTertiary)
                } else {
                    ForEach(habits.prefix(5)) { habit in
                        HStack(spacing: 10) {
                            Image(systemName: habit.icon)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: habit.colorHex))
                                .frame(width: 24)

                            Text(habit.name)
                                .font(FloTypography.caption)
                                .foregroundStyle(FloColors.Hex.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            // Mini streak badge
                            HStack(spacing: 3) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(FloColors.Hex.warning)
                                Text("\(habit.currentStreak)")
                                    .font(FloTypography.caption)
                                    .foregroundStyle(FloColors.Hex.textSecondary)
                            }

                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(FloColors.Hex.border)
                                    Capsule()
                                        .fill(Color(hex: habit.colorHex))
                                        .frame(width: geo.size.width * habitRate(habit))
                                }
                            }
                            .frame(width: 60, height: 6)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Mood Overview

    private var moodOverviewCard: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Mood Trend")
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                if filteredMoodEntries.isEmpty {
                    Text("No mood entries in this period")
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textTertiary)
                } else {
                    HStack(spacing: 16) {
                        StatPill(label: "Average", value: String(format: "%.1f", averageMood), color: moodColor(averageMood))
                        StatPill(label: "Entries", value: "\(filteredMoodEntries.count)", color: FloColors.Hex.textSecondary)
                        StatPill(label: "Best Day", value: bestMoodDay, color: FloColors.Hex.success)
                    }
                }
            }
        }
    }

    // MARK: - Insights

    private var insightsCard: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(FloColors.Hex.warning)
                    Text("Insights")
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                }

                ForEach(generateInsights(), id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(FloColors.Hex.accent)
                            .frame(width: 6, height: 6)
                            .offset(y: 6)

                        Text(insight)
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Computed Data

    private var timeframeStart: Date {
        let days: Int
        switch selectedTimeframe {
        case .week: days = 7
        case .month: days = 30
        case .quarter: days = 90
        case .year: days = 365
        }
        return Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }

    private var completedTaskCount: Int {
        tasks.filter { $0.isCompleted && ($0.completedAt ?? $0.createdAt) >= timeframeStart }.count
    }

    private var filteredFocusSessions: [FocusSession] {
        focusSessions.filter { $0.startedAt >= timeframeStart }
    }

    private var totalFocusHours: Double {
        filteredFocusSessions.reduce(0) { $0 + ($1.actualDuration ?? $1.duration) } / 3600
    }

    private var averageSessionLength: Double {
        guard !filteredFocusSessions.isEmpty else { return 0 }
        return filteredFocusSessions.reduce(0) { $0 + ($1.actualDuration ?? $1.duration) } / Double(filteredFocusSessions.count) / 60
    }

    private var focusCompletionRate: Int {
        guard !filteredFocusSessions.isEmpty else { return 0 }
        let completed = filteredFocusSessions.filter(\.wasCompleted).count
        return Int(Double(completed) / Double(filteredFocusSessions.count) * 100)
    }

    private var habitCompletionCount: Int {
        habits.flatMap(\.completions).filter { $0.date >= timeframeStart }.count
    }

    private var bestOverallStreak: Int {
        habits.map(\.bestStreak).max() ?? 0
    }

    private var completionRate: Int {
        let total = tasks.filter { $0.createdAt >= timeframeStart }.count
        guard total > 0 else { return 0 }
        return Int(Double(completedTaskCount) / Double(total) * 100)
    }

    private var filteredMoodEntries: [MoodEntry] {
        moodEntries.filter { $0.createdAt >= timeframeStart }
    }

    private var averageMood: Double {
        guard !filteredMoodEntries.isEmpty else { return 0 }
        return Double(filteredMoodEntries.reduce(0) { $0 + $1.mood }) / Double(filteredMoodEntries.count)
    }

    private var bestMoodDay: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        var dayAverages: [Int: (sum: Int, count: Int)] = [:]
        for entry in filteredMoodEntries {
            let weekday = calendar.component(.weekday, from: entry.createdAt)
            let current = dayAverages[weekday] ?? (0, 0)
            dayAverages[weekday] = (current.sum + entry.mood, current.count + 1)
        }

        guard let best = dayAverages.max(by: { Double($0.value.sum) / Double($0.value.count) < Double($1.value.sum) / Double($1.value.count) }) else {
            return "—"
        }

        let components = DateComponents(weekday: best.key)
        if let date = calendar.nextDate(after: .now, matching: components, matchingPolicy: .nextTime) {
            return formatter.string(from: date)
        }
        return "—"
    }

    private struct DayData {
        let day: Int
        let label: String
        let count: Int
    }

    private var dailyCompletionData: [DayData] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "E"

        let days: Int
        switch selectedTimeframe {
        case .week: days = 7
        case .month: days = 7  // Show last 7 for readability
        case .quarter: days = 7
        case .year: days = 7
        }

        return (0..<days).map { offset in
            let date = calendar.date(byAdding: .day, value: -(days - 1 - offset), to: .now)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let count = tasks.filter {
                $0.isCompleted &&
                ($0.completedAt ?? $0.createdAt) >= dayStart &&
                ($0.completedAt ?? $0.createdAt) < dayEnd
            }.count
            return DayData(day: offset, label: formatter.string(from: date), count: count)
        }
    }

    private func habitRate(_ habit: Habit) -> Double {
        let daysSinceCreation = max(1, Calendar.current.dateComponents([.day], from: habit.createdAt, to: .now).day ?? 1)
        let completionsInPeriod = habit.completions.filter { $0.date >= timeframeStart }.count
        let expectedDays = min(daysSinceCreation, daysInTimeframe)
        guard expectedDays > 0 else { return 0 }
        return min(1.0, Double(completionsInPeriod) / Double(expectedDays))
    }

    private var daysInTimeframe: Int {
        switch selectedTimeframe {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }

    private func moodColor(_ value: Double) -> Color {
        switch value {
        case 4...: return FloColors.Hex.success
        case 3..<4: return FloColors.Hex.warning
        default: return FloColors.Hex.error
        }
    }

    private func generateInsights() -> [String] {
        var insights: [String] = []

        if completionRate > 70 {
            insights.append("Great job! You're completing \(completionRate)% of your tasks.")
        } else if completionRate > 0 {
            insights.append("Try breaking large tasks into smaller ones to improve your \(completionRate)% completion rate.")
        }

        if totalFocusHours > 10 {
            insights.append("You've logged \(String(format: "%.0f", totalFocusHours)) hours of deep focus. Keep it up!")
        }

        if let topHabit = habits.max(by: { $0.currentStreak < $1.currentStreak }), topHabit.currentStreak > 3 {
            insights.append("Your best habit streak is \(topHabit.name) at \(topHabit.currentStreak) days.")
        }

        if insights.isEmpty {
            insights.append("Start tracking tasks and habits to unlock personalized insights.")
        }

        return insights
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(FloTypography.headline)
                .foregroundStyle(color)
            Text(label)
                .font(FloTypography.caption2)
                .foregroundStyle(FloColors.Hex.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(FloColors.Hex.background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
