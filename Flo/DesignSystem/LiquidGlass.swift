import SwiftUI

// MARK: - Glass Card

/// A card container with liquid glass effect on iOS 26+ and a material fallback on older versions.
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    init(cornerRadius: CGFloat = 20, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .padding(16)
            .modifier(GlassBackgroundModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Button

/// A button styled with liquid glass background.
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(FloColors.Hex.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .modifier(GlassBackgroundModifier(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Sheet Modifier

/// Presents a sheet with glass background on iOS 26+.
struct GlassSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder let sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                sheetContent()
                    .modifier(GlassSheetBackgroundModifier())
            }
    }
}

// MARK: - Glass Tab Bar

/// A custom tab bar with liquid glass effect.
struct GlassTabBar<Tab: Hashable & CaseIterable>: View where Tab: Identifiable {
    @Binding var selection: Tab
    let label: (Tab) -> String
    let icon: (Tab) -> String
    let selectedIcon: (Tab) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selection == tab ? selectedIcon(tab) : icon(tab))
                            .font(.system(size: 20, weight: selection == tab ? .semibold : .regular))
                            .foregroundStyle(selection == tab ? FloColors.Hex.accent : FloColors.Hex.textSecondary)
                            .symbolEffect(.bounce, value: selection == tab)

                        Text(label(tab))
                            .font(.system(size: 10, weight: selection == tab ? .semibold : .regular))
                            .foregroundStyle(selection == tab ? FloColors.Hex.accent : FloColors.Hex.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .modifier(GlassBackgroundModifier(cornerRadius: 24))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Glass Navigation Bar Modifier

/// Applies a glass effect to the navigation bar on iOS 26+.
struct GlassNavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            content
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        } else {
            content
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }
}

// MARK: - Core Glass Background Modifier

/// The core modifier that applies the glass or material background.
struct GlassBackgroundModifier: ViewModifier {
    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = 20) {
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(FloColors.Hex.accentSoft.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(FloColors.Hex.border.opacity(0.3), lineWidth: 0.5)
                    )
            }
    }
}

// MARK: - Glass Sheet Background Modifier

struct GlassSheetBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentationBackground(.ultraThinMaterial)
    }
}

// MARK: - Interactive Glass Modifier

/// Applies an interactive glass effect (responds to touches) on iOS 26+.
struct InteractiveGlassModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(FloColors.Hex.accentSoft.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(FloColors.Hex.border.opacity(0.4), lineWidth: 0.5)
                    )
            }
    }
}

// MARK: - Tab Bar Glass Container Background Modifier

/// Applies glass container background for tab bars on iOS 26+.
struct GlassTabBarContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            content
                .toolbarBackgroundVisibility(.hidden, for: .tabBar)
        } else {
            content
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a liquid glass card background.
    func floGlass(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassBackgroundModifier(cornerRadius: cornerRadius))
    }

    /// Wraps the view in a glass card with padding.
    func floGlassCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .padding(16)
            .modifier(GlassBackgroundModifier(cornerRadius: cornerRadius))
    }

    /// Presents a sheet with glass background.
    func floGlassSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(GlassSheetModifier(isPresented: isPresented, sheetContent: content))
    }

    /// Applies interactive glass effect (responds to touches).
    func floInteractiveGlass(cornerRadius: CGFloat = 14) -> some View {
        modifier(InteractiveGlassModifier(cornerRadius: cornerRadius))
    }

    /// Applies glass navigation bar style.
    func floGlassNavigationBar() -> some View {
        modifier(GlassNavigationBarModifier())
    }

    /// Applies glass tab bar container background.
    func floGlassTabBar() -> some View {
        modifier(GlassTabBarContainerModifier())
    }
}

// MARK: - Preview

#Preview("Glass Card") {
    ZStack {
        FloColors.Hex.background
            .ignoresSafeArea()

        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Progress")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(FloColors.Hex.textPrimary)

                    Text("5 of 8 tasks completed")
                        .font(.system(size: 14))
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GlassButton("Start Focus", icon: "play.fill") {
                // action
            }

            Text("Regular content")
                .floGlassCard()
        }
        .padding()
    }
}
