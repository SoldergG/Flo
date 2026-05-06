import SwiftUI

enum FloTypography {
    // MARK: - Headings
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let title = Font.system(size: 28, weight: .bold, design: .default)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .default)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)

    // MARK: - Body
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)

    // MARK: - Small
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Special
    static let timer = Font.system(size: 64, weight: .light, design: .rounded)
    static let statNumber = Font.system(size: 48, weight: .bold, design: .rounded)
    static let streak = Font.system(size: 36, weight: .bold, design: .rounded)
    static let badge = Font.system(size: 11, weight: .bold, design: .rounded)
}

// MARK: - Text Style Modifier

struct FloTextStyle: ViewModifier {
    let font: Font
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(color)
    }
}

extension View {
    func floText(_ font: Font, color: Color = FloColors.Hex.textPrimary) -> some View {
        modifier(FloTextStyle(font: font, color: color))
    }
}
