import SwiftUI

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("defaultFocusDuration") private var defaultFocusDuration = 25
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("morningReminderEnabled") private var morningReminderEnabled = false
    @AppStorage("eveningReminderEnabled") private var eveningReminderEnabled = false
    @State private var store = StoreKitManager.shared
    @State private var showPaywall = false
    @State private var showWhatsNew = false

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                List {
                    // MARK: - Branding
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
                                HStack(spacing: 8) {
                                    Text("Flō")
                                        .font(FloTypography.title3)
                                        .foregroundStyle(FloColors.Hex.textPrimary)

                                    if store.isPro {
                                        Text("PRO")
                                            .font(FloTypography.badge)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 2)
                                            .background(FloColors.Hex.accent)
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(store.isPro ? "Pro plan active" : "Free plan")
                                    .font(FloTypography.caption)
                                    .foregroundStyle(FloColors.Hex.textSecondary)
                            }
                        }
                        .listRowBackground(FloColors.Hex.surface)
                    }

                    // MARK: - Subscription
                    if !store.isPro {
                        Section {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(FloColors.Hex.accent)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Upgrade to Pro")
                                            .font(FloTypography.headline)
                                            .foregroundStyle(FloColors.Hex.textPrimary)
                                        Text("Unlock all features & remove ads")
                                            .font(FloTypography.caption)
                                            .foregroundStyle(FloColors.Hex.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(FloColors.Hex.accent)
                                }
                            }
                            .listRowBackground(FloColors.Hex.accentSoft.opacity(0.5))
                        }
                    } else {
                        Section("Subscription") {
                            HStack {
                                Label("Plan", systemImage: "crown.fill")
                                Spacer()
                                Text(store.currentPlan.displayName)
                                    .font(FloTypography.subheadline)
                                    .foregroundStyle(FloColors.Hex.accent)
                            }

                            Button("Manage Subscription") {
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    #if os(iOS)
                                    UIApplication.shared.open(url)
                                    #elseif os(macOS)
                                    NSWorkspace.shared.open(url)
                                    #endif
                                }
                            }
                            .foregroundStyle(FloColors.Hex.accent)
                        }
                        .listRowBackground(FloColors.Hex.surface)
                    }

                    // MARK: - Personalization
                    Section("Personalization") {
                        NavigationLink {
                            ThemePickerView()
                        } label: {
                            Label("Appearance", systemImage: "paintbrush.fill")
                        }

                        NavigationLink {
                            AppIconView()
                        } label: {
                            Label("App Icon", systemImage: "app.badge.fill")
                        }
                    }
                    .listRowBackground(FloColors.Hex.surface)

                    // MARK: - Focus
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

                    // MARK: - Notifications
                    Section("Notifications") {
                        Toggle(isOn: $morningReminderEnabled) {
                            Label("Morning Check-in", systemImage: "sunrise.fill")
                        }
                        .tint(FloColors.Hex.accent)
                        .onChange(of: morningReminderEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.scheduleMorningReminder()
                            } else {
                                NotificationManager.cancelNotification(identifier: "morning-checkin")
                            }
                        }

                        Toggle(isOn: $eveningReminderEnabled) {
                            Label("Evening Review", systemImage: "moon.stars.fill")
                        }
                        .tint(FloColors.Hex.accent)
                        .onChange(of: eveningReminderEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.scheduleEveningReminder()
                            } else {
                                NotificationManager.cancelNotification(identifier: "evening-review")
                            }
                        }
                    }
                    .listRowBackground(FloColors.Hex.surface)

                    // MARK: - AI
                    Section("AI") {
                        NavigationLink {
                            AISettingsView()
                        } label: {
                            Label("AI Settings", systemImage: "brain.fill")
                        }

                        NavigationLink {
                            AIFeaturesHubView()
                        } label: {
                            Label {
                                HStack {
                                    Text("All AI Features")
                                    Spacer()
                                    Text("50")
                                        .font(FloTypography.badge)
                                        .foregroundStyle(FloColors.Hex.accent)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(FloColors.Hex.accentSoft)
                                        .clipShape(Capsule())
                                }
                            } icon: {
                                Image(systemName: "sparkles")
                            }
                        }

                        NavigationLink {
                            AIAssistantView()
                        } label: {
                            Label("AI Assistant", systemImage: "bubble.left.and.bubble.right.fill")
                        }
                    }
                    .listRowBackground(FloColors.Hex.surface)

                    // MARK: - Data
                    Section("Data") {
                        HStack {
                            Label("Cloud Sync", systemImage: "icloud.fill")
                            Spacer()
                            if store.isPro {
                                Text("Active")
                                    .font(FloTypography.caption)
                                    .foregroundStyle(FloColors.Hex.success)
                            } else {
                                Text("Pro only")
                                    .font(FloTypography.caption)
                                    .foregroundStyle(FloColors.Hex.textTertiary)
                            }
                        }

                        NavigationLink {
                            DataExportView()
                        } label: {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }

                        NavigationLink {
                            AdvancedStatsView()
                        } label: {
                            Label("Statistics", systemImage: "chart.bar.fill")
                        }
                    }
                    .listRowBackground(FloColors.Hex.surface)

                    // MARK: - About
                    Section("About") {
                        // FIX #56: version from Bundle (not hardcoded)
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(FloColors.Hex.textTertiary)
                        }

                        Button {
                            showWhatsNew = true
                        } label: {
                            Label("What's New", systemImage: "sparkles")
                                .foregroundStyle(FloColors.Hex.accent)
                        }

                        Button("Restore Purchases") {
                            Task { await store.restorePurchases() }
                        }
                        .foregroundStyle(FloColors.Hex.accent)

                        // FIX #57: removed "Reset Onboarding" from production UI (dev-only)
                        // FIX #58: real privacy/terms links (GitHub page)
                        Link("Privacy Policy", destination: URL(string: "https://github.com/SoldergG/Flo#license")!)
                            .foregroundStyle(FloColors.Hex.accent)

                        Link("Source Code", destination: URL(string: "https://github.com/SoldergG/Flo")!)
                            .foregroundStyle(FloColors.Hex.accent)
                    }
                    .listRowBackground(FloColors.Hex.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showWhatsNew) {
                WhatsNewView()
            }
        }
    }
}
