import SwiftUI

// MARK: - What's New View

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var animatedItems: Set<Int> = []

    private let features: [NewFeature] = [
        NewFeature(
            icon: "sparkles",
            title: "50+ AI Features",
            description: "Smart task suggestions, daily briefings, mood analysis, and more — powered by AI.",
            color: Color(hex: "8B5CF6")
        ),
        NewFeature(
            icon: "timer",
            title: "Focus Sessions",
            description: "Pomodoro-style focus timer with ambient sounds, presets, and detailed reports.",
            color: FloColors.Hex.accent
        ),
        NewFeature(
            icon: "flame.fill",
            title: "Habit Tracking",
            description: "Build and track daily habits with streaks, categories, and freeze protection.",
            color: FloColors.Hex.warning
        ),
        NewFeature(
            icon: "rectangle.split.3x1",
            title: "Kanban & Matrix",
            description: "Visualize tasks with Kanban boards and Eisenhower priority matrix.",
            color: Color(hex: "4A90D9")
        ),
        NewFeature(
            icon: "note.text",
            title: "Smart Notes",
            description: "Rich notes with folders, templates, pinning, and word count tracking.",
            color: FloColors.Hex.success
        ),
        NewFeature(
            icon: "chart.bar.fill",
            title: "Productivity Score",
            description: "Track your daily productivity across tasks, habits, and focus sessions.",
            color: FloColors.Hex.error
        ),
        NewFeature(
            icon: "cloud.fill",
            title: "Cloud Sync",
            description: "Sync data across devices with Supabase-powered cloud storage.",
            color: Color(hex: "6366F1")
        ),
        NewFeature(
            icon: "brain.head.profile.fill",
            title: "Mindful Planning",
            description: "Morning check-ins, evening reviews, and guided journaling prompts.",
            color: Color(hex: "EC4899")
        ),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection

                    // Feature List
                    VStack(spacing: 12) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            featureRow(feature, index: index)
                                .opacity(animatedItems.contains(index) ? 1 : 0)
                                .offset(y: animatedItems.contains(index) ? 0 : 20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .background(FloColors.Hex.background)
            .overlay(alignment: .bottom) {
                // CTA button
                Button {
                    dismiss()
                } label: {
                    Text("Get Started")
                        .font(FloTypography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(FloColors.Hex.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .background(
                    LinearGradient(
                        colors: [FloColors.Hex.background.opacity(0), FloColors.Hex.background],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(FloColors.Hex.textTertiary)
                    }
                }
            }
            .onAppear { animateItems() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("What's New in")
                .font(FloTypography.title2)
                .foregroundStyle(FloColors.Hex.textSecondary)

            Text("Flo")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [FloColors.Hex.accent, FloColors.Hex.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Version 1.0")
                .font(FloTypography.caption)
                .foregroundStyle(FloColors.Hex.textTertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(FloColors.Hex.surface)
                .clipShape(Capsule())
        }
        .padding(.top, 20)
        .padding(.bottom, 32)
    }

    // MARK: - Feature Row

    private func featureRow(_ feature: NewFeature, index: Int) -> some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 20))
                .foregroundStyle(feature.color)
                .frame(width: 44, height: 44)
                .background(feature.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(FloTypography.headline)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text(feature.description)
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Animation

    private func animateItems() {
        for i in features.indices {
            _ = withAnimation(FloAnimations.springDefault.delay(Double(i) * 0.08)) {
                animatedItems.insert(i)
            }
        }
    }
}

// MARK: - Feature Model

private struct NewFeature {
    let icon: String
    let title: String
    let description: String
    let color: Color
}
