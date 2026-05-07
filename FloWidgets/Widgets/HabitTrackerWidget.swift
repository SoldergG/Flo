import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Provider

struct HabitTrackerProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitTrackerEntry {
        HabitTrackerEntry(date: .now, habits: WidgetDataProvider.snapshotHabits)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitTrackerEntry) -> Void) {
        completion(HabitTrackerEntry(date: .now, habits: WidgetDataProvider.snapshotHabits))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitTrackerEntry>) -> Void) {
        let habits = WidgetDataProvider.loadHabits()
        let entry = HabitTrackerEntry(date: .now, habits: habits)

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct HabitTrackerEntry: TimelineEntry {
    let date: Date
    let habits: [WidgetHabitData]

    var completedCount: Int {
        habits.filter { $0.isCompletedToday }.count
    }

    var totalCount: Int {
        habits.count
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
}

// MARK: - Colors

private enum HabitColors {
    static let background = Color(red: 250/255, green: 246/255, blue: 241/255)
    static let accent = Color(red: 217/255, green: 119/255, blue: 87/255)
    static let textPrimary = Color(red: 26/255, green: 22/255, blue: 18/255)
    static let textSecondary = Color(red: 107/255, green: 93/255, blue: 82/255)
    static let success = Color(red: 91/255, green: 163/255, blue: 124/255)
    static let border = Color(red: 232/255, green: 224/255, blue: 214/255)
}

// MARK: - Small View

struct HabitTrackerSmallView: View {
    let entry: HabitTrackerEntry

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(HabitColors.border.opacity(0.3), lineWidth: 5)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(HabitColors.success, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(entry.completedCount)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(HabitColors.textPrimary)

                    Text("of \(entry.totalCount)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(HabitColors.textSecondary)
                }
            }
            .frame(width: 70, height: 70)

            Text("Habits")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HabitColors.textSecondary)
        }
        .padding(12)
        .widgetBackground(HabitColors.background)
    }
}

// MARK: - Medium View (Interactive)

struct HabitTrackerMediumView: View {
    let entry: HabitTrackerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("Today's Habits")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HabitColors.textPrimary)

                Spacer()

                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(HabitColors.success)
            }

            // Habit circles row
            if entry.habits.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "plus.circle.dashed")
                            .font(.system(size: 28))
                            .foregroundStyle(HabitColors.border)
                        Text("No habits yet")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(HabitColors.textSecondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                HStack(spacing: 0) {
                    ForEach(entry.habits.prefix(6)) { habit in
                        Button(intent: ToggleHabitIntent(
                            habitId: habit.id,
                            name: habit.name,
                            icon: habit.icon
                        )) {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(habit.isCompletedToday ? HabitColors.success : Color.clear)
                                        .frame(width: 36, height: 36)

                                    Circle()
                                        .strokeBorder(
                                            habit.isCompletedToday ? HabitColors.success : HabitColors.border,
                                            lineWidth: 2
                                        )
                                        .frame(width: 36, height: 36)

                                    if habit.isCompletedToday {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                    } else {
                                        Image(systemName: habit.icon)
                                            .font(.system(size: 14))
                                            .foregroundStyle(HabitColors.textSecondary)
                                    }
                                }

                                Text(habit.name)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(HabitColors.textSecondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .widgetBackground(HabitColors.background)
    }
}

// MARK: - Widget

struct HabitTrackerWidget: Widget {
    let kind = "HabitTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitTrackerProvider()) { entry in
            HabitTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Tracker")
        .description("Track and toggle your daily habits.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HabitTrackerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: HabitTrackerEntry

    var body: some View {
        switch family {
        case .systemSmall:
            HabitTrackerSmallView(entry: entry)
        case .systemMedium:
            HabitTrackerMediumView(entry: entry)
        default:
            HabitTrackerSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    HabitTrackerWidget()
} timeline: {
    HabitTrackerEntry(date: .now, habits: WidgetDataProvider.snapshotHabits)
}

#Preview(as: .systemSmall) {
    HabitTrackerWidget()
} timeline: {
    HabitTrackerEntry(date: .now, habits: WidgetDataProvider.snapshotHabits)
}
