import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct ProductivityScoreProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProductivityScoreEntry {
        ProductivityScoreEntry(date: .now, score: WidgetDataProvider.snapshotScore)
    }

    func getSnapshot(in context: Context, completion: @escaping (ProductivityScoreEntry) -> Void) {
        completion(ProductivityScoreEntry(date: .now, score: WidgetDataProvider.snapshotScore))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProductivityScoreEntry>) -> Void) {
        let score = WidgetDataProvider.loadScore()
        let entry = ProductivityScoreEntry(date: .now, score: score)

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct ProductivityScoreEntry: TimelineEntry {
    let date: Date
    let score: WidgetScoreData
}

// MARK: - Colors

private enum ScoreColors {
    static let background = Color(red: 250/255, green: 246/255, blue: 241/255)
    static let textPrimary = Color(red: 26/255, green: 22/255, blue: 18/255)
    static let textSecondary = Color(red: 107/255, green: 93/255, blue: 82/255)
    static let border = Color(red: 232/255, green: 224/255, blue: 214/255)

    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 80...100: return Color(red: 91/255, green: 163/255, blue: 124/255)   // Green
        case 60..<80:  return Color(red: 217/255, green: 119/255, blue: 87/255)    // Terracotta
        case 40..<60:  return Color(red: 229/255, green: 168/255, blue: 75/255)    // Amber
        default:       return Color(red: 217/255, green: 79/255, blue: 79/255)     // Red
        }
    }

    static func scoreGradient(for score: Int) -> AngularGradient {
        let color = scoreColor(for: score)
        return AngularGradient(
            colors: [color.opacity(0.6), color, color.opacity(0.6)],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }
}

// MARK: - Small View

struct ProductivityScoreSmallView: View {
    let entry: ProductivityScoreEntry

    private var progress: Double {
        Double(entry.score.score) / 100.0
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(ScoreColors.border.opacity(0.3), lineWidth: 6)

                // Score ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        ScoreColors.scoreGradient(for: entry.score.score),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Score number
                VStack(spacing: 0) {
                    Text("\(entry.score.score)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(ScoreColors.textPrimary)
                        .contentTransition(.numericText())

                    Text("score")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ScoreColors.textSecondary)
                }
            }
            .frame(width: 80, height: 80)

            // Breakdown
            HStack(spacing: 10) {
                MiniStat(
                    icon: "checkmark",
                    value: "\(entry.score.tasksCompleted)/\(entry.score.tasksTotal)",
                    color: ScoreColors.scoreColor(for: entry.score.score)
                )

                MiniStat(
                    icon: "flame",
                    value: "\(entry.score.habitsCompleted)/\(entry.score.habitsTotal)",
                    color: ScoreColors.scoreColor(for: entry.score.score)
                )
            }
        }
        .padding(12)
        .widgetBackground(ScoreColors.background)
    }
}

struct MiniStat: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 107/255, green: 93/255, blue: 82/255))
        }
    }
}

// MARK: - Widget

struct ProductivityScoreWidget: Widget {
    let kind = "ProductivityScoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProductivityScoreProvider()) { entry in
            ProductivityScoreSmallView(entry: entry)
        }
        .configurationDisplayName("Productivity Score")
        .description("See today's productivity score at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    ProductivityScoreWidget()
} timeline: {
    ProductivityScoreEntry(date: .now, score: WidgetDataProvider.snapshotScore)
    ProductivityScoreEntry(date: .now, score: WidgetScoreData(
        score: 42, tasksCompleted: 2, tasksTotal: 8, habitsCompleted: 1, habitsTotal: 4, focusMinutes: 20
    ))
}
