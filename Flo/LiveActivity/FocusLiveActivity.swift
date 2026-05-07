#if canImport(ActivityKit)
import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Focus Activity Attributes

struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: TimeInterval
        var progress: Double
        var isPaused: Bool
    }

    var taskName: String
    var totalDuration: TimeInterval
    var startedAt: Date
}

// MARK: - Focus Live Activity Widget

struct FocusLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            // Lock Screen banner
            FocusLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "D97757"))
                        Text("Focus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatTime(context.state.timeRemaining))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "D97757"))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                DynamicIslandExpandedRegion(.center) {
                    if !context.attributes.taskName.isEmpty {
                        Text(context.attributes.taskName)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(Color(hex: "D97757"))
                        .scaleEffect(y: 1.5)
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "D97757"))
            } compactTrailing: {
                Text(formatTime(context.state.timeRemaining))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "D97757"))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            } minimal: {
                Image(systemName: "timer")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "D97757"))
            }
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Lock Screen View

private struct FocusLockScreenView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Timer circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: context.state.progress)
                    .stroke(Color(hex: "D97757"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "D97757"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.isPaused ? "Paused" : "Focusing")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                if !context.attributes.taskName.isEmpty {
                    Text(context.attributes.taskName)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(formatTime(context.state.timeRemaining))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "D97757"))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(16)
        .background(Color.black.opacity(0.6))
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#endif
