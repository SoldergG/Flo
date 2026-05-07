import WidgetKit
import SwiftUI

// MARK: - Shared Lock Screen Colors

private enum LockScreenColors {
    static let accent = Color(red: 217/255, green: 119/255, blue: 87/255)
    static let success = Color(red: 91/255, green: 163/255, blue: 124/255)
    static let flameStart = Color(red: 255/255, green: 149/255, blue: 0/255)
    static let flameEnd = Color(red: 255/255, green: 94/255, blue: 58/255)
}

// MARK: - ============================================
// MARK: - Task Count Circular (Lock Screen)
// MARK: - ============================================

struct TaskCountLockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskCountLockScreenEntry {
        TaskCountLockScreenEntry(date: .now, pending: 5, completed: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskCountLockScreenEntry) -> Void) {
        completion(TaskCountLockScreenEntry(date: .now, pending: 5, completed: 3))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskCountLockScreenEntry>) -> Void) {
        let tasks = WidgetDataProvider.loadTasks()
        let pending = tasks.filter { !$0.isCompleted }.count
        let completed = tasks.filter { $0.isCompleted }.count
        let entry = TaskCountLockScreenEntry(date: .now, pending: pending, completed: completed)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct TaskCountLockScreenEntry: TimelineEntry {
    let date: Date
    let pending: Int
    let completed: Int

    var total: Int { pending + completed }
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
}

struct TaskCountCircularView: View {
    let entry: TaskCountLockScreenEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 1) {
                Text("\(entry.pending)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .widgetAccentable()

                Text("tasks")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetLabel {
            ProgressView(value: entry.progress)
                .tint(LockScreenColors.accent)
        }
    }
}

struct TaskCountLockScreenWidget: Widget {
    let kind = "TaskCountLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskCountLockScreenProvider()) { entry in
            TaskCountCircularView(entry: entry)
        }
        .configurationDisplayName("Task Count")
        .description("Pending tasks at a glance.")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - ============================================
// MARK: - Streak Circular (Lock Screen)
// MARK: - ============================================

struct StreakLockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakLockScreenEntry {
        StreakLockScreenEntry(date: .now, streak: 12)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakLockScreenEntry) -> Void) {
        completion(StreakLockScreenEntry(date: .now, streak: 12))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakLockScreenEntry>) -> Void) {
        let habits = WidgetDataProvider.loadHabits()
        let bestStreak = habits.map(\.currentStreak).max() ?? 0
        let entry = StreakLockScreenEntry(date: .now, streak: bestStreak)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct StreakLockScreenEntry: TimelineEntry {
    let date: Date
    let streak: Int
}

struct StreakCircularView: View {
    let entry: StreakLockScreenEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .widgetAccentable()

                Text("\(entry.streak)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .widgetAccentable()
            }
        }
    }
}

struct StreakLockScreenWidget: Widget {
    let kind = "StreakLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakLockScreenProvider()) { entry in
            StreakCircularView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Your best current streak.")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - ============================================
// MARK: - Focus Minutes Rectangular (Lock Screen)
// MARK: - ============================================

struct FocusMinutesLockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusMinutesLockScreenEntry {
        FocusMinutesLockScreenEntry(date: .now, minutes: 85, isActive: true, remaining: "15:30")
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusMinutesLockScreenEntry) -> Void) {
        completion(FocusMinutesLockScreenEntry(date: .now, minutes: 85, isActive: true, remaining: "15:30"))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusMinutesLockScreenEntry>) -> Void) {
        let focus = WidgetDataProvider.loadFocus()
        let entry = FocusMinutesLockScreenEntry(
            date: .now,
            minutes: focus.todayMinutes,
            isActive: focus.isActive,
            remaining: focus.isActive ? focus.remainingFormatted : nil
        )
        let interval: TimeInterval = focus.isActive ? 60 : 900
        let nextUpdate = Date.now.addingTimeInterval(interval)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct FocusMinutesLockScreenEntry: TimelineEntry {
    let date: Date
    let minutes: Int
    let isActive: Bool
    let remaining: String?
}

struct FocusMinutesRectangularView: View {
    let entry: FocusMinutesLockScreenEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .semibold))
                    .widgetAccentable()

                Text("Focus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            if entry.isActive, let remaining = entry.remaining {
                HStack(spacing: 4) {
                    Text(remaining)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .widgetAccentable()

                    Text("remaining")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 4) {
                    Text("\(entry.minutes)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .widgetAccentable()

                    Text("min today")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FocusMinutesLockScreenWidget: Widget {
    let kind = "FocusMinutesLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusMinutesLockScreenProvider()) { entry in
            FocusMinutesRectangularView(entry: entry)
        }
        .configurationDisplayName("Focus Minutes")
        .description("Today's focus time or active session.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - ============================================
// MARK: - Next Task Inline (Lock Screen)
// MARK: - ============================================

struct NextTaskInlineProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextTaskInlineEntry {
        NextTaskInlineEntry(date: .now, taskTitle: "Review design mockups", hasTasks: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextTaskInlineEntry) -> Void) {
        completion(NextTaskInlineEntry(date: .now, taskTitle: "Review design mockups", hasTasks: true))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextTaskInlineEntry>) -> Void) {
        let tasks = WidgetDataProvider.loadTasks()
        let nextTask = tasks
            .filter { !$0.isCompleted }
            .sorted { t1, t2 in
                let d1 = t1.dueDate ?? t1.scheduledDate ?? .distantFuture
                let d2 = t2.dueDate ?? t2.scheduledDate ?? .distantFuture
                if t1.priorityRaw != t2.priorityRaw {
                    return t1.priorityRaw < t2.priorityRaw
                }
                return d1 < d2
            }
            .first

        let entry = NextTaskInlineEntry(
            date: .now,
            taskTitle: nextTask?.title,
            hasTasks: nextTask != nil
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct NextTaskInlineEntry: TimelineEntry {
    let date: Date
    let taskTitle: String?
    let hasTasks: Bool
}

struct NextTaskInlineView: View {
    let entry: NextTaskInlineEntry

    var body: some View {
        if let title = entry.taskTitle {
            ViewThatFits {
                Label {
                    Text(title)
                } icon: {
                    Image(systemName: "arrow.right.circle.fill")
                }

                Label {
                    Text(title)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "arrow.right.circle.fill")
                }
            }
        } else {
            Label {
                Text("All tasks complete")
            } icon: {
                Image(systemName: "checkmark.circle.fill")
            }
        }
    }
}

struct NextTaskInlineWidget: Widget {
    let kind = "NextTaskInlineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextTaskInlineProvider()) { entry in
            NextTaskInlineView(entry: entry)
        }
        .configurationDisplayName("Next Task")
        .description("Your most important upcoming task.")
        .supportedFamilies([.accessoryInline])
    }
}

// MARK: - Previews

#Preview(as: .accessoryCircular) {
    TaskCountLockScreenWidget()
} timeline: {
    TaskCountLockScreenEntry(date: .now, pending: 5, completed: 3)
}

#Preview(as: .accessoryCircular) {
    StreakLockScreenWidget()
} timeline: {
    StreakLockScreenEntry(date: .now, streak: 12)
}

#Preview(as: .accessoryRectangular) {
    FocusMinutesLockScreenWidget()
} timeline: {
    FocusMinutesLockScreenEntry(date: .now, minutes: 85, isActive: true, remaining: "15:30")
    FocusMinutesLockScreenEntry(date: .now, minutes: 45, isActive: false, remaining: nil)
}

#Preview(as: .accessoryInline) {
    NextTaskInlineWidget()
} timeline: {
    NextTaskInlineEntry(date: .now, taskTitle: "Review design mockups", hasTasks: true)
    NextTaskInlineEntry(date: .now, taskTitle: nil, hasTasks: false)
}
