import SwiftUI

struct ProductivityScoreView: View {
    @State private var score: Int = 72

    var body: some View {
        ZStack {
            FloColors.Hex.background.ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(FloColors.Hex.border.opacity(0.2), lineWidth: 12)
                        .frame(width: 160, height: 160)

                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100)
                        .stroke(FloColors.Hex.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Text("\(score)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(FloColors.Hex.textPrimary)
                        Text("Score")
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                    }
                }

                Text("Your productivity score is based on task completion, habit streaks, and focus sessions.")
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .navigationTitle("Productivity Score")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
