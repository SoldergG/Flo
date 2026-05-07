import SwiftUI
import SwiftData

struct FocusReportView: View {
    @Query(sort: \FocusSession.createdAt, order: .reverse)
    private var sessions: [FocusSession]

    @State private var selectedPeriod: ReportPeriod = .week
    @State private var animateCharts = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        periodPicker
                        summaryCards
                        dailyChart
                        productivityInsights
                        focusStreaks
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Focus Report")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                withAnimation(FloAnimations.springSmooth.delay(0.3)) {
                    animateCharts = true
                }
            }
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: 8) {
            ForEach(ReportPeriod.allCases) { period in
                FilterChip(label: period.label, isSelected: selectedPeriod == period) {
                    withAnimation(FloAnimations.springSnappy) {
                        selectedPeriod = period
                        animateCharts = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(FloAnimations.springSmooth) { animateCharts = true }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                FloStatCard(
                    title: "Sessions",
                    value: "\(periodSessions.count)",
                    icon: "flame.fill",
                    color: FloColors.Hex.accent
                )

                FloStatCard(
                    title: "Total",
                    value: formatMinutes(totalMinutes),
                    icon: "clock.fill",
                    color: FloColors.Hex.success
                )
            }

            HStack(spacing: 12) {
                FloStatCard(
                    title: "Avg / Day",
                    value: formatMinutes(avgMinutesPerDay),
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color(hex: "4A90D9")
                )

                FloStatCard(
                    title: "Completion",
                    value: "\(completionRate)%",
                    icon: "checkmark.circle.fill",
                    color: FloColors.Hex.warning
                )
            }
        }
    }

    // MARK: - Daily Chart

    private var dailyChart: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Daily Focus")
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                let data = dailyChartData
                let maxVal = max(data.map(\.minutes).max() ?? 1, 1)

                HStack(alignment: .bottom, spacing: selectedPeriod == .month ? 3 : 8) {
                    ForEach(data) { day in
                        VStack(spacing: 4) {
                            if selectedPeriod == .week {
                                Text("\(day.minutes)")
                                    .font(FloTypography.caption2)
                                    .foregroundStyle(FloColors.Hex.textSecondary)
                            }

                            RoundedRectangle(cornerRadius: selectedPeriod == .month ? 2 : 5)
                                .fill(
                                    day.isToday
                                        ? FloColors.Hex.accent
                                        : day.minutes > 0 ? FloColors.Hex.accent.opacity(0.5) : FloColors.Hex.border.opacity(0.2)
                                )
                                .frame(
                                    height: animateCharts
                                        ? max(CGFloat(day.minutes) / CGFloat(maxVal) * 120, 4)
                                        : 4
                                )

                            if selectedPeriod == .week {
                                Text(day.label)
                                    .font(FloTypography.caption2)
                                    .foregroundStyle(day.isToday ? FloColors.Hex.accent : FloColors.Hex.textTertiary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: selectedPeriod == .week ? 180 : 140)
                .animation(FloAnimations.springSmooth, value: animateCharts)

                if selectedPeriod == .month {
                    HStack {
                        Text("Start")
                            .font(FloTypography.caption2)
                            .foregroundStyle(FloColors.Hex.textTertiary)
                        Spacer()
                        Text("Today")
                            .font(FloTypography.caption2)
                            .foregroundStyle(FloColors.Hex.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Productivity Insights

    private var productivityInsights: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Productivity Insights")
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                VStack(spacing: 12) {
                    insightRow(
                        icon: "sun.max.fill",
                        title: "Most Productive Day",
                        value: bestDay,
                        color: FloColors.Hex.warning
                    )

                    insightRow(
                        icon: "clock.fill",
                        title: "Peak Focus Time",
                        value: peakTime,
                        color: FloColors.Hex.accent
                    )

                    insightRow(
                        icon: "timer",
                        title: "Avg Session",
                        value: formatMinutes(avgSessionMinutes),
                        color: FloColors.Hex.success
                    )

                    insightRow(
                        icon: "target",
                        title: "Longest Session",
                        value: formatMinutes(longestSession),
                        color: Color(hex: "8B5CF6")
                    )
                }
            }
        }
    }

    private func insightRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(title)
                .font(FloTypography.subheadline)
                .foregroundStyle(FloColors.Hex.textSecondary)

            Spacer()

            Text(value)
                .font(FloTypography.headline)
                .foregroundStyle(FloColors.Hex.textPrimary)
        }
    }

    // MARK: - Streaks

    private var focusStreaks: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Focus Streaks")
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(currentStreak)")
                            .font(FloTypography.streak)
                            .foregroundStyle(FloColors.Hex.accent)
                        Text("Current")
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 50)

                    VStack(spacing: 4) {
                        Text("\(bestStreak)")
                            .font(FloTypography.streak)
                            .foregroundStyle(FloColors.Hex.success)
                        Text("Best")
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Computed Data

    private var periodSessions: [FocusSession] {
        let dayCount = selectedPeriod == .week ? 7 : 30
        let start = calendar.date(byAdding: .day, value: -dayCount, to: calendar.startOfDay(for: .now))!
        return sessions.filter { $0.createdAt >= start }
    }

    private var totalMinutes: Int {
        periodSessions.reduce(0) { $0 + Int(($1.actualDuration ?? $1.duration) / 60) }
    }

    private var avgMinutesPerDay: Int {
        let days = selectedPeriod == .week ? 7 : 30
        return days > 0 ? totalMinutes / days : 0
    }

    private var completionRate: Int {
        guard !periodSessions.isEmpty else { return 0 }
        return periodSessions.filter(\.wasCompleted).count * 100 / periodSessions.count
    }

    private var avgSessionMinutes: Int {
        guard !periodSessions.isEmpty else { return 0 }
        return totalMinutes / periodSessions.count
    }

    private var longestSession: Int {
        let maxDuration = periodSessions.map { $0.actualDuration ?? $0.duration }.max() ?? 0
        return Int(maxDuration / 60)
    }

    private var bestDay: String {
        var dayMinutes: [Int: Int] = [:]
        for s in periodSessions {
            let weekday = calendar.component(.weekday, from: s.createdAt)
            dayMinutes[weekday, default: 0] += Int((s.actualDuration ?? s.duration) / 60)
        }
        guard let best = dayMinutes.max(by: { $0.value < $1.value }) else { return "N/A" }
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[best.key - 1]
    }

    private var peakTime: String {
        var hourCounts: [Int: Int] = [:]
        for s in periodSessions {
            let hour = calendar.component(.hour, from: s.startedAt)
            hourCounts[hour, default: 0] += 1
        }
        guard let bestHour = hourCounts.max(by: { $0.value < $1.value }) else { return "N/A" }
        let h = bestHour.key
        let ampm = h >= 12 ? "PM" : "AM"
        let displayHour = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return "\(displayHour) \(ampm)"
    }

    private var currentStreak: Int {
        let completedDates = Set(sessions.filter(\.wasCompleted).map { calendar.startOfDay(for: $0.createdAt) })
        var streak = 0
        var checkDate = calendar.startOfDay(for: .now)

        while completedDates.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streak
    }

    private var bestStreak: Int {
        let completedDates = Set(sessions.filter(\.wasCompleted).map { calendar.startOfDay(for: $0.createdAt) })
        let sorted = completedDates.sorted()
        guard sorted.count > 0 else { return 0 }

        var best = 1
        var current = 1
        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day ?? 0
            if diff == 1 { current += 1; best = max(best, current) }
            else if diff > 1 { current = 1 }
        }
        return best
    }

    private var dailyChartData: [FocusDayChartData] {
        let dayCount = selectedPeriod == .week ? 7 : 30
        let today = calendar.startOfDay(for: .now)

        return (0..<dayCount).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: date)!
            let daySessions = sessions.filter { $0.createdAt >= date && $0.createdAt < dayEnd }
            let minutes = daySessions.reduce(0) { $0 + Int(($1.actualDuration ?? $1.duration) / 60) }

            return FocusDayChartData(
                label: date.formatted(.dateTime.weekday(.narrow)),
                minutes: minutes,
                isToday: offset == 0
            )
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }
}

// MARK: - Supporting Types

private enum ReportPeriod: String, CaseIterable, Identifiable {
    case week, month
    var id: String { rawValue }
    var label: String {
        switch self {
        case .week: "This Week"
        case .month: "This Month"
        }
    }
}

private struct FocusDayChartData: Identifiable {
    let id = UUID()
    let label: String
    let minutes: Int
    let isToday: Bool
}
