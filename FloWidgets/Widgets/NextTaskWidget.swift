import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct NextTaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextTaskEntry {
        NextTaskEntry(date: .now, task: WidgetDataProvider.snapshotTasks.first)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextTaskEntry) -> Void) {
        completion(NextTaskEntry(date: .now, task: WidgetDataProvider.snapshotTasks.first))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextTaskEntry>) -> Void) {
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

        let entry = NextTaskEntry(date: .now, task: nextTask)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct NextTaskEntry: TimelineEntry {
    let date: Date
    let task: WidgetTaskData?
}

// MARK: - Colors

private enum TaskColors {
    static let background = Color(red: 250/255, green: 246/255, blue: 241/255)
    static let accent = Color(red: 217/255, green: 119/255, blue: 87/255)
    static let textPrimary = Color(red: 26/255, green: 22/255, blue: 18/255)
    static let textSecondary = Color(red: 107/255, green: 93/255, blue: 82/255)
    static let border = Color(red: 232/255, green: 224/255, blue: 214/255)

    static func priority(_ raw: Int) -> Color {
        switch raw {
        case 1: return Color(red: 217/255, green: 79/255, blue: 79/255)
        case 2: return Color(red: 229/255, green: 168/255, blue: 75/255)
        case 3: return Color(red: 91/255, green: 163/255, blue: 124/255)
        default: return Color(red: 229/255, green: 168/255, blue: 75/255)
        }
    }
}

// MARK: - Small View

struct NextTaskSmallView: View {
    let entry: NextTaskEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let task = entry.task {
                // Priority indicator
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(TaskColors.priority(task.priorityRaw))
                        .frame(width: 4, height: 16)

                    Text("Next Up")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(TaskColors.textSecondary)
                        .textCase(.uppercase)
                }

                Text(task.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(TaskColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Project + Due
                VStack(alignment: .leading, spacing: 3) {
                    if let project = task.projectName {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: task.projectColorHex ?? "D97757"))
                                .frame(width: 6, height: 6)

                            Text(project)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(TaskColors.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    if let due = task.dueDate {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                                .foregroundStyle(due < .now ? Color(red: 217/255, green: 79/255, blue: 79/255) : TaskColors.textSecondary)

                            Text(due, style: .relative)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(due < .now ? Color(red: 217/255, green: 79/255, blue: 79/255) : TaskColors.textSecondary)
                        }
                    }
                }
            } else {
                // No tasks
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(TaskColors.accent.opacity(0.5))

                    Text("All clear!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TaskColors.textPrimary)

                    Text("No pending tasks")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(TaskColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .padding(14)
        .widgetBackground(TaskColors.background)
    }
}

// MARK: - Color extension for widget (not importing main app)

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

// MARK: - Widget

struct NextTaskWidget: Widget {
    let kind = "NextTaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextTaskProvider()) { entry in
            NextTaskSmallView(entry: entry)
        }
        .configurationDisplayName("Next Task")
        .description("See your most important upcoming task.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    NextTaskWidget()
} timeline: {
    NextTaskEntry(date: .now, task: WidgetDataProvider.snapshotTasks.first)
    NextTaskEntry(date: .now, task: nil)
}
