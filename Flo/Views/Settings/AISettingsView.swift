import SwiftUI

// MARK: - AI Settings View

struct AISettingsView: View {
    @AppStorage("groq_api_key") private var apiKey = ""
    @State private var draftKey = ""
    @State private var isSecure = true
    @State private var showSaved = false
    @State private var isTesting = false
    @State private var testResult: TestResult?

    enum TestResult {
        case success(String)
        case failure(String)
    }

    var hasKey: Bool { !apiKey.isEmpty && apiKey != "gsk_placeholder" }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status card
                statusCard

                // Key input
                keyInputCard

                // How to get a key
                howToGetKeyCard

                // Model info
                modelInfoCard
            }
            .padding(20)
        }
        .background(FloColors.Hex.background.ignoresSafeArea())
        .navigationTitle("AI Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .onAppear { draftKey = apiKey }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        FloCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(hasKey ? FloColors.Hex.success.opacity(0.15) : FloColors.Hex.warning.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: hasKey ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(hasKey ? FloColors.Hex.success : FloColors.Hex.warning)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(hasKey ? "AI Ready" : "No API key set")
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                    Text(hasKey
                        ? "Powered by Groq · Llama 3.3 70B"
                        : "AI features will use offline fallback tips")
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Key Input Card

    private var keyInputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Groq API Key")
                .font(FloTypography.headline)
                .foregroundStyle(FloColors.Hex.textPrimary)

            // Key field
            HStack(spacing: 10) {
                Image(systemName: "key.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(FloColors.Hex.textTertiary)

                Group {
                    if isSecure {
                        SecureField("gsk_••••••••••••••••••••", text: $draftKey)
                    } else {
                        TextField("gsk_••••••••••••••••••••", text: $draftKey)
                    }
                }
                .font(FloTypography.body)
                .foregroundStyle(FloColors.Hex.textPrimary)
                #if os(iOS)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                #endif

                Button {
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundStyle(FloColors.Hex.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(FloColors.Hex.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(FloColors.Hex.border, lineWidth: 1)
            )

            // Action buttons
            HStack(spacing: 10) {
                Button {
                    saveKey()
                } label: {
                    HStack(spacing: 6) {
                        if showSaved {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Text(showSaved ? "Saved!" : "Save Key")
                            .font(FloTypography.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(draftKey.isEmpty ? FloColors.Hex.border : FloColors.Hex.accent)
                    .foregroundStyle(draftKey.isEmpty ? FloColors.Hex.textSecondary : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(draftKey.isEmpty)

                if hasKey {
                    Button {
                        testConnection()
                    } label: {
                        HStack(spacing: 6) {
                            if isTesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(FloColors.Hex.accent)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 13))
                            }
                            Text(isTesting ? "Testing…" : "Test")
                                .font(FloTypography.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(FloColors.Hex.surface)
                        .foregroundStyle(FloColors.Hex.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(FloColors.Hex.accent, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isTesting)
                }
            }

            // Test result
            if let result = testResult {
                switch result {
                case .success(let msg):
                    Label(msg, systemImage: "checkmark.circle.fill")
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.success)
                case .failure(let msg):
                    Label(msg, systemImage: "xmark.circle.fill")
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.error)
                }
            }

            // Clear key
            if hasKey {
                Button {
                    draftKey = ""
                    apiKey = ""
                } label: {
                    Text("Remove key")
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.error)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - How-to Card

    private var howToGetKeyCard: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(FloColors.Hex.accent)
                    Text("How to get a free key")
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    step("1", "Go to console.groq.com")
                    step("2", "Create a free account")
                    step("3", "Go to API Keys → Create API Key")
                    step("4", "Copy the key (starts with gsk_) and paste it above")
                }

                Text("Groq's free tier gives 14,400 requests/day — more than enough for daily use.")
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textTertiary)
                    .padding(.top, 4)
            }
        }
    }

    private func step(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(FloColors.Hex.accent)
                .clipShape(Circle())
            Text(text)
                .font(FloTypography.body)
                .foregroundStyle(FloColors.Hex.textSecondary)
        }
    }

    // MARK: - Model Info Card

    private var modelInfoCard: some View {
        FloCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "cpu")
                        .foregroundStyle(FloColors.Hex.textSecondary)
                    Text("Model")
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                }
                HStack {
                    Text("Llama 3.3 70B (via Groq)")
                        .font(FloTypography.body)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                    Spacer()
                    Text("Free tier")
                        .font(FloTypography.badge)
                        .foregroundStyle(FloColors.Hex.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(FloColors.Hex.success.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Actions

    private func saveKey() {
        let trimmed = draftKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        apiKey = trimmed
        UserDefaults.standard.set(trimmed, forKey: "groq_api_key")
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaved = false }
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil
        Task {
            do {
                let response = try await FloAIService.shared.chat(
                    prompt: "Reply with exactly: OK",
                    systemPrompt: "You are a test bot. Reply only with: OK"
                )
                isTesting = false
                if response.uppercased().contains("OK") {
                    testResult = .success("Connected! Groq API is working.")
                } else {
                    testResult = .success("Connected! Got a response from Groq.")
                }
            } catch {
                isTesting = false
                testResult = .failure("Failed: \(error.localizedDescription)")
            }
        }
    }
}
