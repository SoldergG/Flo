import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct TodaySummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodaySummaryEntry {
        TodaySummaryEntry(
            date: .now,
            tasks: WidgetDataProvider.snapshotTasks,
            habits: WidgetDataProvider.snapshotHabits,
            focusMinutes: 85
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodaySummaryEntry) -> Void) {
        let entry = TodaySummaryEntry(
            date: .now,
            tasks: WidgetDataProvider.snapshotTasks,
            habits: WidgetDataProvider.snapshotHabits,
            focusMinutes: 85
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodaySummaryEntry>) -> Void) {
        let tasks = WidgetDataProvider.loadTasks()
        let habits = WidgetDataProvider.loadHabits()
        let focus = WidgetDataProvider.loadFocus()

        let entry = TodaySummaryEntry(
            date: .now,
            tasks: tasks,
            habits: habits,
            focusMinutes: focus.todayMinutes
        )

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct TodaySummaryEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTaskData]
    let habits: [WidgetHabitData]
    let focusMinutes: Int

    var pendingTasks: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    var completedTasks: Int {
        tasks.filter { $0.isCompleted }.count
    }

    var completedHabits: Int {
        habits.filter { $0.isCompletedToday }.count
    }

    var totalHabits: Int {
        habits.count
    }

    var habitProgress: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedHabits) / Double(totalHabits)
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }
}

// MARK: - Widget Colors

private enum WidgetColors {
    static let background = Color(red: 250/255, green: 246/255, blue: 241/255)
    static let accent = Color(red: 217/255, green: 119/255, blue: 87/255)
    static let accentSecondary = Color(red: 184/255, green: 96/255, blue: 46/255)
    static let textPrimary = Color(red: 26/255, green: 22/255, blue: 18/255)
    static let textSecondary = Color(red: 107/255, green: 93/255, blue: 82/255)
    static let success = Color(red: 91/255, green: 163/255, blue: 124/255)
    static let border = Color(red: 232/255, green: 224/255, blue: 214/255)
    static let surface = Color.white
}

// MARK: - Small View

struct TodaySummarySmallView: View {
    let entry: TodaySummaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.pendingTasks)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetColors.textPrimary)
                        .contentTransition(.numericText())

                    Text("tasks left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(WidgetColors.textSecondary)
                }

                Spacer()

                // Habit ring
                ZStack {
                    Circle()
                        .stroke(WidgetColors.border.opacity(0.4), lineWidth: 4)

                    Circle()
                        .trim(from: 0, to: entry.habitProgress)
                        .stroke(WidgetColors.success, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(entry.habitProgress >= 1.0 ? WidgetColors.success : WidgetColors.accent)
                }
                .frame(width: 40, height: 40)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetColors.success)

                Text("\(entry.completedTasks) done")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WidgetColors.textSecondary)
            }
        }
        .padding(16)
        .widgetBackground(WidgetColors.background)
    }
}

// MARK: - Medium View

struct TodaySummaryMediumView: View {
    let entry: TodaySummaryEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Greeting + Tasks
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.greeting)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(WidgetColors.textSecondary)

                Text("\(entry.pendingTasks) tasks")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetColors.textPrimary)

                Spacer()

                HStack(spacing: 12) {
                    Label("\(entry.completedTasks) done", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(WidgetColors.success)

                    Label("\(entry.focusMinutes)m", systemImage: "timer")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(WidgetColors.accent)
                }
            }

            Spacer()

            // Right: Habit ring
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(WidgetColors.border.opacity(0.3), lineWidth: 5)

                    Circle()
                        .trim(from: 0, to: entry.habitProgress)
                        .stroke(
                            WidgetColors.success,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(entry.completedHabits)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(WidgetColors.textPrimary)

                        Text("of \(entry.totalHabits)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(WidgetColors.textSecondary)
                    }
                }
                .frame(width: 70, height: 70)

                Text("Habits")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WidgetColors.textSecondary)
            }
        }
        .padding(16)
        .widgetBackground(WidgetColors.background)
    }
}

// MARK: - Widget

struct TodaySummaryWidget: Widget {
    let kind = "TodaySummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodaySummaryProvider()) { entry in
            TodaySummaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Summary")
        .description("See your tasks, habits, and focus progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TodaySummaryWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TodaySummaryEntry

    var body: some View {
        switch family {
        case .systemSmall:
            TodaySummarySmallView(entry: entry)
        case .systemMedium:
            TodaySummaryMediumView(entry: entry)
        default:
            TodaySummarySmallView(entry: entry)
        }
    }
}

// MARK: - Container Background Modifier

extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            return AnyView(
                self.containerBackground(for: .widget) {
                    color.glassEffect()
                }
            )
        } else if #available(iOSApplicationExtension 17.0, macOSApplicationExtension 14.0, *) {
            return AnyView(
                self.containerBackground(for: .widget) {
                    color
                }
            )
        } else {
            return AnyView(
                self.background(color)
            )
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TodaySummaryWidget()
} timeline: {
    TodaySummaryEntry(
        date: .now,
        tasks: WidgetDataProvider.snapshotTasks,
        habits: WidgetDataProvider.snapshotHabits,
        focusMinutes: 85
    )
}

#Preview(as: .systemMedium) {
    TodaySummaryWidget()
} timeline: {
    TodaySummaryEntry(
        date: .now,
        tasks: WidgetDataProvider.snapshotTasks,
        habits: WidgetDataProvider.snapshotHabits,
        focusMinutes: 85
    )
}
