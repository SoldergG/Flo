import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct FocusTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusTimerEntry {
        FocusTimerEntry(date: .now, focus: WidgetDataProvider.snapshotFocus)
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusTimerEntry) -> Void) {
        completion(FocusTimerEntry(date: .now, focus: WidgetDataProvider.snapshotFocus))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusTimerEntry>) -> Void) {
        let focus = WidgetDataProvider.loadFocus()
        let entry = FocusTimerEntry(date: .now, focus: focus)

        // If active, update more frequently
        let interval: TimeInterval = focus.isActive ? 60 : 900
        let nextUpdate = Date.now.addingTimeInterval(interval)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct FocusTimerEntry: TimelineEntry {
    let date: Date
    let focus: WidgetFocusData
}

// MARK: - Colors

private enum FocusColors {
    static let background = Color(red: 250/255, green: 246/255, blue: 241/255)
    static let accent = Color(red: 217/255, green: 119/255, blue: 87/255)
    static let accentSecondary = Color(red: 184/255, green: 96/255, blue: 46/255)
    static let textPrimary = Color(red: 26/255, green: 22/255, blue: 18/255)
    static let textSecondary = Color(red: 107/255, green: 93/255, blue: 82/255)
    static let border = Color(red: 232/255, green: 224/255, blue: 214/255)
}

// MARK: - Small View

struct FocusTimerSmallView: View {
    let entry: FocusTimerEntry

    var body: some View {
        VStack(spacing: 8) {
            if entry.focus.isActive {
                // Active session - show ring
                ZStack {
                    Circle()
                        .stroke(FocusColors.border.opacity(0.3), lineWidth: 5)

                    Circle()
                        .trim(from: 0, to: entry.focus.progress)
                        .stroke(
                            AngularGradient(
                                colors: [FocusColors.accent, FocusColors.accentSecondary, FocusColors.accent],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text(entry.focus.remainingFormatted)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(FocusColors.textPrimary)

                        Text("left")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(FocusColors.textSecondary)
                    }
                }
                .frame(width: 80, height: 80)

                if let task = entry.focus.taskTitle {
                    Text(task)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(FocusColors.textSecondary)
                        .lineLimit(1)
                }
            } else {
                // Idle - show start prompt
                Spacer()

                ZStack {
                    Circle()
                        .stroke(FocusColors.border.opacity(0.3), lineWidth: 5)

                    Circle()
                        .fill(FocusColors.accent.opacity(0.1))

                    Image(systemName: "play.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(FocusColors.accent)
                }
                .frame(width: 60, height: 60)

                Text("Start Focus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FocusColors.textPrimary)

                Text("\(entry.focus.todayMinutes)m today")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(FocusColors.textSecondary)

                Spacer()
            }
        }
        .padding(12)
        .widgetBackground(FocusColors.background)
    }
}

// MARK: - Widget

struct FocusTimerWidget: Widget {
    let kind = "FocusTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusTimerProvider()) { entry in
            FocusTimerSmallView(entry: entry)
        }
        .configurationDisplayName("Focus Timer")
        .description("Track your current focus session or start a new one.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    FocusTimerWidget()
} timeline: {
    FocusTimerEntry(date: .now, focus: WidgetDataProvider.snapshotFocus)
    FocusTimerEntry(date: .now, focus: WidgetFocusData(
        isActive: false, totalDuration: 0, elapsed: 0, taskTitle: nil, todayMinutes: 45
    ))
}
