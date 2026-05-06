import SwiftUI

struct FloCard<Content: View>: View {
    let content: Content
    var padding: CGFloat
    var cornerRadius: CGFloat

    init(padding: CGFloat = 16, cornerRadius: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .padding(padding)
            .background(FloColors.Hex.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Pressable Card

struct FloPressableCard<Content: View>: View {
    let content: Content
    let action: () -> Void
    @State private var isPressed = false

    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            content
                .padding(16)
                .background(FloColors.Hex.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(isPressed ? 0.02 : 0.04), radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 1 : 2)
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(FloAnimations.springSnappy, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Stat Card

struct FloStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: 28, height: 28)
                        .background(color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Spacer()
                }

                Text(value)
                    .font(FloTypography.title2)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text(title)
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textSecondary)
            }
        }
    }
}
