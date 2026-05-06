import SwiftUI

enum FloColors {
    // MARK: - Backgrounds
    static let background = Color("Background", bundle: .main)
    static let surface = Color("Surface", bundle: .main)
    static let surfaceElevated = Color("SurfaceElevated", bundle: .main)

    // MARK: - Accent
    static let accent = Color("AccentPrimary", bundle: .main)
    static let accentSecondary = Color("AccentSecondary", bundle: .main)
    static let accentSoft = Color("AccentSoft", bundle: .main)

    // MARK: - Text
    static let textPrimary = Color("TextPrimary", bundle: .main)
    static let textSecondary = Color("TextSecondary", bundle: .main)
    static let textTertiary = Color("TextTertiary", bundle: .main)

    // MARK: - Semantic
    static let success = Color("Success", bundle: .main)
    static let warning = Color("Warning", bundle: .main)
    static let error = Color("Error", bundle: .main)
    static let border = Color("Border", bundle: .main)

    // MARK: - Priority Colors
    static let priorityHigh = Color("PriorityHigh", bundle: .main)
    static let priorityMedium = Color("PriorityMedium", bundle: .main)
    static let priorityLow = Color("PriorityLow", bundle: .main)

    // MARK: - Fallback hex values (used if asset catalog not configured)
    enum Hex {
        static let background = Color(hex: "FAF6F1")
        static let surface = Color(hex: "FFFFFF")
        static let surfaceElevated = Color(hex: "FFFFFF")
        static let accent = Color(hex: "D97757")
        static let accentSecondary = Color(hex: "B8602E")
        static let accentSoft = Color(hex: "FDF0E9")
        static let textPrimary = Color(hex: "1A1612")
        static let textSecondary = Color(hex: "6B5D52")
        static let textTertiary = Color(hex: "9B8E82")
        static let success = Color(hex: "5BA37C")
        static let warning = Color(hex: "E5A84B")
        static let error = Color(hex: "D94F4F")
        static let border = Color(hex: "E8E0D6")
        static let priorityHigh = Color(hex: "D94F4F")
        static let priorityMedium = Color(hex: "E5A84B")
        static let priorityLow = Color(hex: "5BA37C")
    }
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Environment

struct FloTheme {
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let accent: Color
    let accentSecondary: Color
    let accentSoft: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let success: Color
    let warning: Color
    let error: Color
    let border: Color

    static let `default` = FloTheme(
        background: FloColors.Hex.background,
        surface: FloColors.Hex.surface,
        surfaceElevated: FloColors.Hex.surfaceElevated,
        accent: FloColors.Hex.accent,
        accentSecondary: FloColors.Hex.accentSecondary,
        accentSoft: FloColors.Hex.accentSoft,
        textPrimary: FloColors.Hex.textPrimary,
        textSecondary: FloColors.Hex.textSecondary,
        textTertiary: FloColors.Hex.textTertiary,
        success: FloColors.Hex.success,
        warning: FloColors.Hex.warning,
        error: FloColors.Hex.error,
        border: FloColors.Hex.border
    )

    static let dark = FloTheme(
        background: Color(hex: "1A1612"),
        surface: Color(hex: "252019"),
        surfaceElevated: Color(hex: "302A22"),
        accent: Color(hex: "D97757"),
        accentSecondary: Color(hex: "E8956F"),
        accentSoft: Color(hex: "3D2E24"),
        textPrimary: Color(hex: "FAF6F1"),
        textSecondary: Color(hex: "B8A99A"),
        textTertiary: Color(hex: "7D7068"),
        success: Color(hex: "5BA37C"),
        warning: Color(hex: "E5A84B"),
        error: Color(hex: "D94F4F"),
        border: Color(hex: "3D3428")
    )
}

struct FloThemeKey: EnvironmentKey {
    static let defaultValue = FloTheme.default
}

extension EnvironmentValues {
    var floTheme: FloTheme {
        get { self[FloThemeKey.self] }
        set { self[FloThemeKey.self] = newValue }
    }
}
