import SwiftUI

struct FloProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 12
    var size: CGFloat = 200
    var showPercentage: Bool = true
    var accentColor: Color = FloColors.Hex.accent

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(FloColors.Hex.border.opacity(0.3), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    accentColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(FloAnimations.springSmooth, value: animatedProgress)

            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(FloTypography.title2)
                    .foregroundStyle(FloColors.Hex.textPrimary)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(FloAnimations.springSmooth.delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(FloAnimations.springSmooth) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Timer Ring

struct FloTimerRing: View {
    let progress: Double
    let timeRemaining: TimeInterval
    var size: CGFloat = 260

    var body: some View {
        ZStack {
            Circle()
                .stroke(FloColors.Hex.border.opacity(0.2), lineWidth: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [FloColors.Hex.accent, FloColors.Hex.accentSecondary, FloColors.Hex.accent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(FloColors.Hex.accent)
                .frame(width: 14, height: 14)
                .offset(y: -size / 2)
                .rotationEffect(.degrees(360 * progress - 90))
                .shadow(color: FloColors.Hex.accent.opacity(0.4), radius: 4)

            VStack(spacing: 4) {
                Text(timeString)
                    .font(FloTypography.timer)
                    .foregroundStyle(FloColors.Hex.textPrimary)
                    .monospacedDigit()

                Text("remaining")
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textTertiary)
            }
        }
        .frame(width: size, height: size)
    }

    private var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Habit Ring (small)

struct FloHabitRing: View {
    let completed: Int
    let total: Int
    var size: CGFloat = 44

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(FloColors.Hex.border.opacity(0.3), lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(FloColors.Hex.success, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(completed)")
                .font(FloTypography.badge)
                .foregroundStyle(FloColors.Hex.textPrimary)
        }
        .frame(width: size, height: size)
    }
}
