import SwiftUI
import SwiftData

struct FocusHistoryView: View {
    @Query(sort: \FocusSession.createdAt, order: .reverse)
    private var sessions: [FocusSession]

    @State private var animateChart = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        weeklyStats
                        weeklyChart
                        sessionsList
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Focus History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                withAnimation(FloAnimations.springSmooth.delay(0.3)) {
                    animateChart = true
                }
            }
        }
    }

    // MARK: - Weekly Stats

    private var weeklyStats: some View {
        HStack(spacing: 12) {
            FloStatCard(
                title: "This Week",
                value: "\(weekSessions.count)",
                icon: "flame.fill",
                color: FloColors.Hex.accent
            )

            FloStatCard(
                title: "Total Minutes",
                value: "\(weekTotalMinutes)",
                icon: "clock.fill",
                color: FloColors.Hex.success
            )

            FloStatCard(
                title: "Completion",
                value: "\(weekCompletionRate)%",
                icon: "checkmark.circle.fill",
                color: FloColors.Hex.warning
            )
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Focus Minutes This Week")
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                let data = dailyFocusData
                let maxMinutes = max(data.map(\.minutes).max() ?? 1, 1)

                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(data) { day in
                        VStack(spacing: 6) {
                            Text("\(day.minutes)")
                                .font(FloTypography.caption2)
                                .foregroundStyle(day.minutes > 0 ? FloColors.Hex.textSecondary : FloColors.Hex.textTertiary)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    day.isToday
                                        ? FloColors.Hex.accent
                                        : day.minutes > 0 ? FloColors.Hex.accent.opacity(0.5) : FloColors.Hex.border.opacity(0.3)
                                )
                                .frame(
                                    height: animateChart
                                        ? max(CGFloat(day.minutes) / CGFloat(maxMinutes) * 120, 6)
                                        : 6
                                )

                            Text(day.label)
                                .font(FloTypography.caption2)
                                .foregroundStyle(day.isToday ? FloColors.Hex.accent : FloColors.Hex.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 160)
                .animation(FloAnimations.springSmooth, value: animateChart)
            }
        }
    }

    // MARK: - Sessions List

    private var sessionsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Sessions")
                .font(FloTypography.headline)
                .foregroundStyle(FloColors.Hex.textPrimary)

            if sessions.isEmpty {
                FloCard {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(FloColors.Hex.border)
                        Text("No focus sessions yet")
                            .font(FloTypography.body)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                        Spacer()
                    }
                }
            } else {
                let grouped = groupedSessions
                ForEach(grouped.keys.sorted(by: >), id: \.self) { dateKey in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dateLabel(dateKey))
                            .font(FloTypography.footnote)
                            .foregroundStyle(FloColors.Hex.textTertiary)
                            .textCase(.uppercase)
                            .padding(.top, 8)

                        ForEach(grouped[dateKey] ?? []) { session in
                            sessionRow(session)
                        }
                    }
                }
            }
        }
    }

    private func sessionRow(_ session: FocusSession) -> some View {
        FloCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(session.wasCompleted ? FloColors.Hex.success.opacity(0.15) : FloColors.Hex.border.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: session.wasCompleted ? "checkmark.circle.fill" : "xmark.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(session.wasCompleted ? FloColors.Hex.success : FloColors.Hex.textTertiary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("\(session.durationMinutes) min session")
                            .font(FloTypography.subheadline)
                            .foregroundStyle(FloColors.Hex.textPrimary)

                        if session.wasCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(FloColors.Hex.success)
                        }
                    }

                    HStack(spacing: 8) {
                        if let task = session.task {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.system(size: 10))
                                Text(task.title)
                                    .font(FloTypography.caption)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(FloColors.Hex.textSecondary)
                        }

                        Text(session.startedAt.formatted(date: .omitted, time: .shortened))
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textTertiary)
                    }
                }

                Spacer()

                if let actual = session.actualDuration {
                    Text("\(Int(actual / 60))m")
                        .font(FloTypography.badge)
                        .foregroundStyle(FloColors.Hex.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(FloColors.Hex.accentSoft)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Computed Data

    private var weekSessions: [FocusSession] {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else { return [] }
        return sessions.filter { $0.createdAt >= weekStart }
    }

    private var weekTotalMinutes: Int {
        weekSessions.reduce(0) { $0 + Int(($1.actualDuration ?? $1.duration) / 60) }
    }

    private var weekCompletionRate: Int {
        guard !weekSessions.isEmpty else { return 0 }
        let completed = weekSessions.filter(\.wasCompleted).count
        return completed * 100 / weekSessions.count
    }

    private var dailyFocusData: [FocusDayData] {
        let today = calendar.startOfDay(for: .now)

        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: date)!
            let daySessions = sessions.filter { $0.createdAt >= date && $0.createdAt < dayEnd }
            let minutes = daySessions.reduce(0) { $0 + Int(($1.actualDuration ?? $1.duration) / 60) }

            return FocusDayData(
                label: date.formatted(.dateTime.weekday(.narrow)),
                minutes: minutes,
                isToday: offset == 0
            )
        }
    }

    private var groupedSessions: [Date: [FocusSession]] {
        Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.createdAt) }
    }

    private func dateLabel(_ date: Date) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}

// MARK: - Focus Day Data

private struct FocusDayData: Identifiable {
    let id = UUID()
    let label: String
    let minutes: Int
    let isToday: Bool
}
