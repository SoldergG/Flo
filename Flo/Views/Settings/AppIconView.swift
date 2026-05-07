import SwiftUI

// MARK: - App Icon Chooser

struct AppIconView: View {
    @State private var selectedIcon: String = "Default"
    @State private var showConfirmation = false

    private let icons: [AppIconOption] = [
        AppIconOption(name: "Default", displayName: "Terracotta", previewColor: Color(hex: "D97757")),
        AppIconOption(name: "Dark", displayName: "Midnight", previewColor: Color(hex: "1A1612")),
        AppIconOption(name: "Ocean", displayName: "Ocean Blue", previewColor: Color(hex: "4A90D9")),
        AppIconOption(name: "Forest", displayName: "Forest Green", previewColor: Color(hex: "5BA37C")),
        AppIconOption(name: "Sunset", displayName: "Sunset Gold", previewColor: Color(hex: "E5A84B")),
        AppIconOption(name: "Berry", displayName: "Berry Purple", previewColor: Color(hex: "8B5CF6")),
    ]

    var body: some View {
        List {
            Section {
                ForEach(icons) { icon in
                    Button {
                        selectIcon(icon)
                    } label: {
                        HStack(spacing: 16) {
                            // Icon preview
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [icon.previewColor, icon.previewColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .overlay {
                                    Text("F")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                                .shadow(color: icon.previewColor.opacity(0.3), radius: 4, y: 2)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(icon.displayName)
                                    .font(FloTypography.headline)
                                    .foregroundStyle(FloColors.Hex.textPrimary)

                                Text(icon.name == "Default" ? "Classic Flo" : "Alternative style")
                                    .font(FloTypography.caption)
                                    .foregroundStyle(FloColors.Hex.textTertiary)
                            }

                            Spacer()

                            if selectedIcon == icon.name {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(FloColors.Hex.accent)
                                    .font(.system(size: 22))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Choose App Icon")
            } footer: {
                Text("Select your preferred app icon for the home screen.")
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textTertiary)
            }
        }
        .navigationTitle("App Icon")
        #if os(iOS)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        #else
        .listStyle(.sidebar)
        #endif
        .background(FloColors.Hex.background)
    }

    private func selectIcon(_ icon: AppIconOption) {
        withAnimation(FloAnimations.springSnappy) {
            selectedIcon = icon.name
        }
        HapticManager.trigger(.success)

        #if os(iOS)
        let iconName: String? = icon.name == "Default" ? nil : "AppIcon-\(icon.name)"
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error {
                print("Failed to change icon: \(error.localizedDescription)")
            }
        }
        #endif
    }
}

// MARK: - App Icon Option

private struct AppIconOption: Identifiable {
    let name: String
    let displayName: String
    let previewColor: Color
    var id: String { name }
}
