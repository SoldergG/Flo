import SwiftUI

struct FloButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle {
        case primary
        case secondary
        case ghost
        case destructive
    }

    init(_ title: String, icon: String? = nil, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(FloTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: style == .secondary ? 1.5 : 0)
            )
        }
        .buttonStyle(.plain)
        .bounceOnTap()
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: FloColors.Hex.accent
        case .secondary: .clear
        case .ghost: .clear
        case .destructive: FloColors.Hex.error
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: .white
        case .secondary: FloColors.Hex.accent
        case .ghost: FloColors.Hex.textSecondary
        case .destructive: .white
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary: FloColors.Hex.accent
        default: .clear
        }
    }
}

// MARK: - Icon Button

struct FloIconButton: View {
    let icon: String
    let size: CGFloat
    let color: Color
    let action: () -> Void

    init(_ icon: String, size: CGFloat = 20, color: Color = FloColors.Hex.textSecondary, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .bounceOnTap()
    }
}
