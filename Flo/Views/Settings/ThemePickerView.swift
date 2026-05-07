import SwiftUI

// MARK: - Theme Picker View

struct ThemePickerView: View {
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @AppStorage("accentColorHex") private var accentColorHex = "D97757"

    private let themes: [(id: String, label: String, icon: String)] = [
        ("system", "System", "circle.lefthalf.filled"),
        ("light", "Light", "sun.max.fill"),
        ("dark", "Dark", "moon.fill"),
    ]

    private let accentColors: [(hex: String, name: String)] = [
        ("D97757", "Terracotta"),
        ("4A90D9", "Ocean"),
        ("5BA37C", "Forest"),
        ("8B5CF6", "Violet"),
        ("EC4899", "Rose"),
        ("E5A84B", "Amber"),
        ("6366F1", "Indigo"),
        ("EF4444", "Red"),
    ]

    var body: some View {
        List {
            // Appearance Section
            Section {
                ForEach(themes, id: \.id) { theme in
                    Button {
                        withAnimation(FloAnimations.springSnappy) {
                            selectedTheme = theme.id
                        }
                        HapticManager.trigger(.selection)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: theme.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(FloColors.Hex.accent)
                                .frame(width: 28)

                            Text(theme.label)
                                .font(FloTypography.body)
                                .foregroundStyle(FloColors.Hex.textPrimary)

                            Spacer()

                            if selectedTheme == theme.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(FloColors.Hex.accent)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Appearance")
            }

            // Accent Color Section
            Section {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 12) {
                    ForEach(accentColors, id: \.hex) { color in
                        Button {
                            withAnimation(FloAnimations.springSnappy) {
                                accentColorHex = color.hex
                            }
                            HapticManager.trigger(.light)
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: color.hex))
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        if accentColorHex == color.hex {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .fontWeight(.bold)
                                                .font(.system(size: 14))
                                        }
                                    }
                                    .shadow(color: Color(hex: color.hex).opacity(0.3), radius: 4, y: 2)

                                Text(color.name)
                                    .font(FloTypography.caption2)
                                    .foregroundStyle(
                                        accentColorHex == color.hex
                                        ? FloColors.Hex.textPrimary
                                        : FloColors.Hex.textTertiary
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Accent Color")
            } footer: {
                Text("Choose a color that matches your style.")
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textTertiary)
            }

            // Preview Section
            Section("Preview") {
                VStack(spacing: 12) {
                    HStack {
                        Circle()
                            .fill(Color(hex: accentColorHex))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.white)
                                    .fontWeight(.bold)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sample Task")
                                .font(FloTypography.headline)
                                .foregroundStyle(FloColors.Hex.textPrimary)
                            Text("Due tomorrow")
                                .font(FloTypography.caption)
                                .foregroundStyle(FloColors.Hex.textSecondary)
                        }

                        Spacer()

                        Text("Pro")
                            .font(FloTypography.badge)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: accentColorHex))
                            .clipShape(Capsule())
                    }
                    .padding(14)
                    .background(FloColors.Hex.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .navigationTitle("Appearance")
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(FloColors.Hex.background)
    }
}
