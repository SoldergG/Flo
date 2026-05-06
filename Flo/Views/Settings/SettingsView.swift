import SwiftUI

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("defaultFocusDuration") private var defaultFocusDuration = 25
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                List {
                    Section {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(FloColors.Hex.accentSoft)
                                    .frame(width: 52, height: 52)
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(FloColors.Hex.accent)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Flō")
                                    .font(FloTypography.title3)
                                    .foregroundStyle(FloColors.Hex.textPrimary)
                                Text("Focus on what matters")
                                    .font(FloTypography.caption)
                                    .foregroundStyle(FloColors.Hex.textSecondary)
                            }
                        }
                        .listRowBackground(FloColors.Hex.surface)
                    }

                    Section("Focus") {
                        Picker("Default Duration", selection: $defaultFocusDuration) {
                            Text("15 min").tag(15)
                            Text("25 min").tag(25)
                            Text("50 min").tag(50)
                            Text("90 min").tag(90)
                        }
                        .tint(FloColors.Hex.accent)

                        Toggle("Break Reminders", isOn: $notificationsEnabled)
                            .tint(FloColors.Hex.accent)
                    }
                    .listRowBackground(FloColors.Hex.surface)

                    Section("Data") {
                        HStack {
                            Label("iCloud Sync", systemImage: "icloud.fill")
                            Spacer()
                            Text("Active")
                                .font(FloTypography.caption)
                                .foregroundStyle(FloColors.Hex.success)
                        }
                    }
                    .listRowBackground(FloColors.Hex.surface)

                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(FloColors.Hex.textTertiary)
                        }

                        Button("Reset Onboarding") {
                            hasCompletedOnboarding = false
                        }
                        .foregroundStyle(FloColors.Hex.accent)

                        Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                            .foregroundStyle(FloColors.Hex.accent)
                    }
                    .listRowBackground(FloColors.Hex.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
}
