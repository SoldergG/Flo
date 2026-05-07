import SwiftUI

// MARK: - Empty State View

struct FloEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @State private var iconBounce = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(FloColors.Hex.accentSoft.opacity(0.5))
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(FloColors.Hex.accent.opacity(0.6))
                    .symbolEffect(.pulse, options: .repeating.speed(0.5), isActive: iconBounce)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(FloTypography.title3)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text(subtitle)
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            if let actionTitle, let action {
                FloButton(actionTitle, icon: "plus.circle.fill", style: .secondary, action: action)
                    .frame(maxWidth: 220)
            }
        }
        .padding(.horizontal, 40)
        .onAppear { iconBounce = true }
    }
}

// MARK: - Streak Badge

struct StreakBadge: View {
    let count: Int
    var size: StreakSize = .regular

    enum StreakSize {
        case compact, regular, large

        var iconSize: CGFloat {
            switch self {
            case .compact: 12
            case .regular: 16
            case .large: 24
            }
        }
        var textFont: Font {
            switch self {
            case .compact: FloTypography.badge
            case .regular: FloTypography.headline
            case .large: .system(size: 28, weight: .bold, design: .rounded)
            }
        }
        var padding: CGFloat {
            switch self {
            case .compact: 6
            case .regular: 10
            case .large: 14
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: size.iconSize))
                .foregroundStyle(
                    count > 0
                        ? LinearGradient(colors: [FloColors.Hex.warning, FloColors.Hex.accent], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [FloColors.Hex.textTertiary, FloColors.Hex.textTertiary], startPoint: .top, endPoint: .bottom)
                )
                .symbolEffect(.bounce, value: count)

            Text("\(count)")
                .font(size.textFont)
                .foregroundStyle(count > 0 ? FloColors.Hex.textPrimary : FloColors.Hex.textTertiary)
        }
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding * 0.6)
        .background(count > 0 ? FloColors.Hex.warning.opacity(0.12) : FloColors.Hex.surface)
        .clipShape(Capsule())
    }
}

// MARK: - Motivational Tip Card

struct DailyTipCard: View {
    @State private var currentTip: String

    private static let tips = [
        "Start with your hardest task while your energy is highest.",
        "Take a 5-minute break every 25 minutes to stay sharp.",
        "Writing your goals down makes you 42% more likely to achieve them.",
        "Small consistent habits beat big inconsistent efforts.",
        "Celebrate small wins — they fuel motivation for the big ones.",
        "Focus on progress, not perfection.",
        "Your environment shapes your behavior. Design it for success.",
        "The two-minute rule: if it takes less than 2 minutes, do it now.",
        "Review your day every evening to build self-awareness.",
        "Saying no to distractions is saying yes to your goals.",
    ]

    init() {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        _currentTip = State(initialValue: Self.tips[dayOfYear % Self.tips.count])
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundStyle(FloColors.Hex.warning)

            Text(currentTip)
                .font(FloTypography.caption)
                .foregroundStyle(FloColors.Hex.textSecondary)
                .lineLimit(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FloColors.Hex.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
