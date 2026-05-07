import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, habits: WidgetDataProvider.snapshotHabits)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(StreakEntry(date: .now, habits: WidgetDataProvider.snapshotHabits))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let habits = WidgetDataProvider.loadHabits()
        let entry = StreakEntry(date: .now, habits: habits)

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct StreakEntry: TimelineEntry {
    let date: Date
    let habits: [WidgetHabitData]

    var bestCurrentStreak: Int {
        habits.map(\.currentStreak).max() ?? 0
    }

    var bestStreakHabit: WidgetHabitData? {
        habits.max(by: { $0.currentStreak < $1.currentStreak })
    }

    var allTimeBest: Int {
        habits.map(\.bestStreak).max() ?? 0
    }
}

// MARK: - Colors

private enum StreakColors {
    static let background = Color(red: 250/255, green: 246/255, blue: 241/255)
    static let textPrimary = Color(red: 26/255, green: 22/255, blue: 18/255)
    static let textSecondary = Color(red: 107/255, green: 93/255, blue: 82/255)
    static let border = Color(red: 232/255, green: 224/255, blue: 214/255)

    static let flameStart = Color(red: 255/255, green: 149/255, blue: 0/255)
    static let flameMid = Color(red: 255/255, green: 94/255, blue: 58/255)
    static let flameEnd = Color(red: 217/255, green: 79/255, blue: 79/255)

    static var flameGradient: LinearGradient {
        LinearGradient(
            colors: [flameStart, flameMid, flameEnd],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Small View

struct StreakSmallView: View {
    let entry: StreakEntry

    var body: some View {
        VStack(spacing: 6) {
            if entry.bestCurrentStreak > 0 {
                // Flame icon with gradient
                Image(systemName: "flame.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(StreakColors.flameGradient)

                // Streak number
                Text("\(entry.bestCurrentStreak)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(StreakColors.textPrimary)
                    .contentTransition(.numericText())

                Text("day streak")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(StreakColors.textSecondary)

                if let habit = entry.bestStreakHabit {
                    Text(habit.name)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(StreakColors.textSecondary)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(StreakColors.border.opacity(0.5))
                        )
                }
            } else {
                // No streak
                Spacer()

                Image(systemName: "flame")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(StreakColors.border)

                Text("No streak yet")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(StreakColors.textPrimary)

                Text("Complete a habit\nto start")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(StreakColors.textSecondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
        }
        .padding(12)
        .widgetBackground(StreakColors.background)
    }
}

// MARK: - Widget

struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakSmallView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("See your best current habit streak.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakEntry(date: .now, habits: WidgetDataProvider.snapshotHabits)
    StreakEntry(date: .now, habits: [])
}
