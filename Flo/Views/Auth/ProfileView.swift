import SwiftUI
import SwiftData
import Supabase

struct ProfileView: View {
    @State private var authManager = SupabaseManager.shared
    @State private var syncService = SyncService.shared
    @State private var showSignOutAlert = false
    @State private var showDeleteAlert = false
    @State private var showExportSheet = false
    @State private var isEditing = false
    @State private var editedName = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private var userEmail: String {
        authManager.currentUser?.email ?? "No email"
    }

    private var displayName: String {
        if let metadata = authManager.currentUser?.userMetadata,
           let name = extractString(from: metadata["display_name"]) {
            return name
        }
        return authManager.currentUser?.email?.components(separatedBy: "@").first ?? "User"
    }

    private var userInitials: String {
        let components = displayName.components(separatedBy: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0).uppercased() }
        return initials.joined()
    }

    private var memberSince: String {
        if let createdAt = authManager.currentUser?.createdAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: createdAt)
        }
        return "Unknown"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Avatar Section
                avatarSection

                // MARK: - Account Info
                accountInfoSection

                // MARK: - Sync Status
                syncStatusSection

                // MARK: - Actions
                actionsSection

                // MARK: - App Info
                appInfoSection

                // MARK: - Danger Zone
                dangerZoneSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(FloColors.Hex.background.ignoresSafeArea())
        .navigationTitle("Profile")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Task {
                    try? await authManager.signOut()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to sign out? Your local data will remain on this device.")
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    try? await authManager.deleteAccount()
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete your cloud data. Local data will remain on this device. This action cannot be undone.")
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(FloColors.Hex.accent)
                    .frame(width: 96, height: 96)
                    .shadow(color: FloColors.Hex.accent.opacity(0.2), radius: 12, y: 4)

                Text(userInitials)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            if isEditing {
                HStack(spacing: 12) {
                    FloTextField(placeholder: "Display name", text: $editedName)
                        .frame(maxWidth: 220)

                    Button {
                        Task {
                            try? await authManager.updateProfile(displayName: editedName)
                            isEditing = false
                        }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(FloColors.Hex.accent)
                    }
                    .buttonStyle(.plain)

                    Button {
                        isEditing = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(FloColors.Hex.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .transition(FloAnimations.fadeScale)
            } else {
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Text(displayName)
                            .font(FloTypography.title2)
                            .foregroundStyle(FloColors.Hex.textPrimary)

                        Button {
                            editedName = displayName
                            withAnimation(FloAnimations.springDefault) {
                                isEditing = true
                            }
                        } label: {
                            Image(systemName: "pencil.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(FloColors.Hex.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(userEmail)
                        .font(FloTypography.subheadline)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
            }
        }
        .animation(FloAnimations.springDefault, value: isEditing)
    }

    // MARK: - Account Info Section

    private var accountInfoSection: some View {
        FloCard {
            VStack(spacing: 0) {
                profileRow(icon: "calendar", title: "Member since", value: memberSince)

                Divider()
                    .padding(.horizontal, -16)

                profileRow(
                    icon: "person.badge.shield.checkmark",
                    title: "Account ID",
                    value: String(authManager.currentUser?.id.uuidString.prefix(8) ?? "---")
                )
            }
        }
    }

    // MARK: - Sync Status Section

    private var syncStatusSection: some View {
        FloCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: syncService.status.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(syncStatusColor)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cloud Sync")
                            .font(FloTypography.headline)
                            .foregroundStyle(FloColors.Hex.textPrimary)

                        Text(syncService.status.label)
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                    }

                    Spacer()

                    Button {
                        Task {
                            await syncService.syncAll(modelContext: modelContext)
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(FloColors.Hex.accent)
                            .rotationEffect(.degrees(syncService.status == .syncing ? 360 : 0))
                            .animation(
                                syncService.status == .syncing
                                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                                    : .default,
                                value: syncService.status
                            )
                    }
                    .buttonStyle(.plain)
                }

                if let lastSync = syncService.lastSyncDate {
                    HStack {
                        Spacer()
                        Text("Last synced: \(lastSync, style: .relative) ago")
                            .font(FloTypography.caption2)
                            .foregroundStyle(FloColors.Hex.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 2) {
            actionButton(
                icon: "square.and.arrow.up",
                title: "Export Data",
                subtitle: "Download a copy of your data",
                color: FloColors.Hex.accent
            ) {
                Task {
                    if let data = try? await syncService.exportAllData(modelContext: modelContext),
                       let jsonString = String(data: data, encoding: .utf8) {
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(jsonString, forType: .string)
                        #else
                        UIPasteboard.general.string = jsonString
                        #endif
                    }
                }
            }

            actionButton(
                icon: "arrow.clockwise",
                title: "Force Sync",
                subtitle: "Re-sync all data with the cloud",
                color: FloColors.Hex.accent
            ) {
                Task {
                    await syncService.syncAll(modelContext: modelContext)
                }
            }

            actionButton(
                icon: "rectangle.portrait.and.arrow.right",
                title: "Sign Out",
                subtitle: "Your local data will be kept",
                color: FloColors.Hex.warning
            ) {
                showSignOutAlert = true
            }
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        FloCard {
            VStack(spacing: 0) {
                profileRow(
                    icon: "info.circle",
                    title: "Version",
                    value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                )

                Divider()
                    .padding(.horizontal, -16)

                profileRow(
                    icon: "hammer",
                    title: "Build",
                    value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                )
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danger Zone")
                .font(FloTypography.caption)
                .foregroundStyle(FloColors.Hex.error)
                .textCase(.uppercase)
                .padding(.leading, 4)

            actionButton(
                icon: "trash",
                title: "Delete Account",
                subtitle: "Permanently remove your cloud data",
                color: FloColors.Hex.error
            ) {
                showDeleteAlert = true
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private var syncStatusColor: Color {
        switch syncService.status {
        case .idle: FloColors.Hex.textTertiary
        case .syncing: FloColors.Hex.warning
        case .synced: FloColors.Hex.success
        case .error: FloColors.Hex.error
        }
    }

    private func profileRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(FloColors.Hex.textTertiary)
                .frame(width: 24)

            Text(title)
                .font(FloTypography.subheadline)
                .foregroundStyle(FloColors.Hex.textSecondary)

            Spacer()

            Text(value)
                .font(FloTypography.subheadline)
                .foregroundStyle(FloColors.Hex.textPrimary)
        }
        .padding(.vertical, 12)
    }

    private func actionButton(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            FloCard(padding: 14) {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(color)
                        .frame(width: 32, height: 32)
                        .background(color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(FloTypography.headline)
                            .foregroundStyle(FloColors.Hex.textPrimary)

                        Text(subtitle)
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(FloColors.Hex.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .bounceOnTap()
    }
}

// MARK: - AnyJSON String Helper

private func extractString(from json: AnyJSON?) -> String? {
    guard let json else { return nil }
    if case .string(let value) = json {
        return value
    }
    return nil
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileView()
    }
}
