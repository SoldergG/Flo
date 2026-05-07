import SwiftUI
import SwiftData

struct TaskStatsView: View {
    @Query(filter: #Predicate<TaskItem> { $0.parentTask == nil },
           sort: \TaskItem.createdAt, order: .reverse)
    private var allTasks: [TaskItem]

    @State private var selectedPeriod: StatPeriod = .week
    @State private var animateCharts = false

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        periodPicker
                        overviewStats
                        weeklyCompletionChart
                        priorityBreakdown
                        productivityInsights
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Task Stats")
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
            ForEach(StatPeriod.allCases) { period in
                FilterChip(label: period.label, isSelected: selectedPeriod == period) {
                    withAnimation(FloAnimations.springSnappy) {
                        selectedPeriod = period
                    }
                }
            }
        }
    }

    // MARK: - Overview Stats

    private var overviewStats: some View {
        HStack(spacing: 12) {
            FloStatCard(
                title: "Total",
                value: "\(allTasks.count)",
                icon: "list.bullet",
                color: FloColors.Hex.accent
            )

            FloStatCard(
                title: "Completed",
                value: "\(completedTasks.count)",
                icon: "checkmark.circle.fill",
                color: FloColors.Hex.success
            )

            FloStatCard(
                title: "Rate",
                value: "\(completionRate)%",
                icon: "chart.bar.fill",
                color: FloColors.Hex.warning
            )
        }
    }

    // MARK: - Weekly Completion Chart

    private var weeklyCompletionChart: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Completion Trend")
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                let data = weeklyData
                let maxVal = max(data.map(\.completed).max() ?? 1, 1)

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(data) { day in
                        VStack(spacing: 6) {
                            Text("\(day.completed)")
                                .font(FloTypography.caption2)
                                .foregroundStyle(FloColors.Hex.textSecondary)

                            VStack(spacing: 2) {
                                // Completed bar
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(FloColors.Hex.accent)
                                    .frame(
                                        height: animateCharts
                                            ? max(CGFloat(day.completed) / CGFloat(maxVal) * 100, 4)
                                            : 4
                                    )

                                // Total bar (remaining)
                                if day.total - day.completed > 0 {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(FloColors.Hex.border.opacity(0.4))
                                        .frame(
                                            height: animateCharts
                                                ? max(CGFloat(day.total - day.completed) / CGFloat(maxVal) * 100, 2)
                                                : 2
                                        )
                                }
                            }

                            Text(day.label)
                                .font(FloTypography.caption2)
                                .foregroundStyle(
                                    day.isToday ? FloColors.Hex.accent : FloColors.Hex.textTertiary
                                )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 160)
                .animation(FloAnimations.springSmooth, value: animateCharts)

                // Legend
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(FloColors.Hex.accent)
                            .frame(width: 12, height: 12)
                        Text("Completed")
                            .font(FloTypography.caption2)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                    }
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(FloColors.Hex.border.opacity(0.4))
                            .frame(width: 12, height: 12)
                        Text("Remaining")
                            .font(FloTypography.caption2)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Priority Breakdown

    private var priorityBreakdown: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("By Priority")
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                let total = max(allTasks.count, 1)
                let highCount = allTasks.filter { $0.priority == .high }.count
                let mediumCount = allTasks.filter { $0.priority == .medium }.count
                let lowCount = allTasks.filter { $0.priority == .low }.count

                // Donut chart
                ZStack {
                    ForEach(prioritySlices(high: highCount, medium: mediumCount, low: lowCount), id: \.priority) { slice in
                        Circle()
                            .trim(from: animateCharts ? slice.start : 0, to: animateCharts ? slice.end : 0)
                            .stroke(slice.color, style: StrokeStyle(lineWidth: 20, lineCap: .butt))
                            .rotationEffect(.degrees(-90))
                            .animation(FloAnimations.springSmooth, value: animateCharts)
                    }

                    VStack(spacing: 2) {
                        Text("\(total)")
                            .font(FloTypography.title2)
                            .foregroundStyle(FloColors.Hex.textPrimary)
                        Text("tasks")
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textTertiary)
                    }
                }
                .frame(width: 140, height: 140)
                .frame(maxWidth: .infinity)

                // Legend
                VStack(spacing: 8) {
                    priorityRow("High", count: highCount, total: total, color: FloColors.Hex.error)
                    priorityRow("Medium", count: mediumCount, total: total, color: FloColors.Hex.warning)
                    priorityRow("Low", count: lowCount, total: total, color: FloColors.Hex.success)
                }
            }
        }
    }

    private func priorityRow(_ label: String, count: Int, total: Int, color: Color) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(label)
                .font(FloTypography.subheadline)
                .foregroundStyle(FloColors.Hex.textPrimary)

            Spacer()

            Text("\(count)")
                .font(FloTypography.headline)
                .foregroundStyle(FloColors.Hex.textPrimary)

            Text("\(total > 0 ? (count * 100 / total) : 0)%")
                .font(FloTypography.caption)
                .foregroundStyle(FloColors.Hex.textTertiary)
                .frame(width: 36, alignment: .trailing)
        }
    }

    // MARK: - Productivity Insights

    private var productivityInsights: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Insights")
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                VStack(spacing: 12) {
                    insightRow(
                        icon: "clock.fill",
                        title: "Avg. Completion Time",
                        value: averageCompletionTime,
                        color: FloColors.Hex.accent
                    )
                    insightRow(
                        icon: "arrow.up.right",
                        title: "Most Productive Day",
                        value: mostProductiveDay,
                        color: FloColors.Hex.success
                    )
                    insightRow(
                        icon: "flame.fill",
                        title: "Best Streak",
                        value: "\(bestCompletionStreak) days",
                        color: FloColors.Hex.warning
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

    // MARK: - Computed Data

    private var completedTasks: [TaskItem] {
        allTasks.filter(\.isCompleted)
    }

    private var completionRate: Int {
        guard !allTasks.isEmpty else { return 0 }
        return completedTasks.count * 100 / allTasks.count
    }

    private var weeklyData: [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: date)!
            let dayTasks = allTasks.filter {
                if let due = $0.dueDate { return due >= date && due < dayEnd }
                return $0.createdAt >= date && $0.createdAt < dayEnd
            }
            let completed = dayTasks.filter(\.isCompleted).count
            let isToday = offset == 0

            return DayData(
                label: date.formatted(.dateTime.weekday(.narrow)),
                completed: completed,
                total: dayTasks.count,
                isToday: isToday
            )
        }
    }

    private var averageCompletionTime: String {
        let completed = allTasks.filter { $0.isCompleted && $0.completedAt != nil }
        guard !completed.isEmpty else { return "N/A" }

        let total = completed.reduce(0.0) { sum, task in
            sum + (task.completedAt?.timeIntervalSince(task.createdAt) ?? 0)
        }
        let avgHours = total / Double(completed.count) / 3600

        if avgHours < 1 { return "\(Int(avgHours * 60)) min" }
        if avgHours < 24 { return String(format: "%.1f hrs", avgHours) }
        return String(format: "%.1f days", avgHours / 24)
    }

    private var mostProductiveDay: String {
        let calendar = Calendar.current
        var dayCount: [Int: Int] = [:]

        for task in completedTasks {
            if let completedAt = task.completedAt {
                let weekday = calendar.component(.weekday, from: completedAt)
                dayCount[weekday, default: 0] += 1
            }
        }

        guard let bestDay = dayCount.max(by: { $0.value < $1.value }) else { return "N/A" }
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[bestDay.key - 1]
    }

    private var bestCompletionStreak: Int {
        let calendar = Calendar.current
        let completedDates = Set(completedTasks.compactMap { $0.completedAt }.map { calendar.startOfDay(for: $0) })
        guard !completedDates.isEmpty else { return 0 }

        let sorted = completedDates.sorted()
        var best = 1
        var current = 1

        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day ?? 0
            if diff == 1 { current += 1; best = max(best, current) }
            else if diff > 1 { current = 1 }
        }
        return best
    }

    private func prioritySlices(high: Int, medium: Int, low: Int) -> [PrioritySlice] {
        let total = max(Double(high + medium + low), 1)
        let hFrac = Double(high) / total
        let mFrac = Double(medium) / total
        let lFrac = Double(low) / total

        return [
            PrioritySlice(priority: "high", start: 0, end: hFrac, color: FloColors.Hex.error),
            PrioritySlice(priority: "medium", start: hFrac, end: hFrac + mFrac, color: FloColors.Hex.warning),
            PrioritySlice(priority: "low", start: hFrac + mFrac, end: hFrac + mFrac + lFrac, color: FloColors.Hex.success)
        ]
    }
}

// MARK: - Supporting Types

private struct DayData: Identifiable {
    let id = UUID()
    let label: String
    let completed: Int
    let total: Int
    let isToday: Bool
}

private struct PrioritySlice {
    let priority: String
    let start: Double
    let end: Double
    let color: Color
}

private enum StatPeriod: String, CaseIterable, Identifiable {
    case week, month, all
    var id: String { rawValue }
    var label: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .all: "All Time"
        }
    }
}
