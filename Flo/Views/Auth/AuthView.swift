import SwiftUI
import AuthenticationServices

// MARK: - Auth Mode

enum AuthMode {
    case signIn
    case signUp
}

// MARK: - Auth View

struct AuthView: View {
    @State private var authManager = SupabaseManager.shared
    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAnimating = false

    private let appleSignInDelegate = AppleSignInDelegate()

    var body: some View {
        ZStack {
            // Background
            FloColors.Hex.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)

                    // MARK: - Logo & Branding
                    brandingSection

                    Spacer()
                        .frame(height: 48)

                    // MARK: - Auth Form
                    VStack(spacing: 20) {
                        // Sign In with Apple
                        appleSignInButton

                        // Divider
                        dividerRow

                        // Email form
                        emailForm

                        // Submit button
                        submitButton

                        // Toggle mode
                        toggleModeButton
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                        .frame(height: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Loading overlay
            if authManager.isLoading {
                loadingOverlay
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            withAnimation(FloAnimations.easeSlow) {
                isAnimating = true
            }
        }
    }

    // MARK: - Branding Section

    private var brandingSection: some View {
        VStack(spacing: 16) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(FloColors.Hex.accent)
                    .frame(width: 88, height: 88)
                    .shadow(color: FloColors.Hex.accent.opacity(0.3), radius: 20, y: 10)

                Text("F")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .scaleEffect(isAnimating ? 1.0 : 0.5)
            .opacity(isAnimating ? 1.0 : 0)

            VStack(spacing: 8) {
                Text("Flo")
                    .font(FloTypography.largeTitle)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text("Your mindful productivity companion")
                    .font(FloTypography.callout)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(isAnimating ? 1.0 : 0)
            .offset(y: isAnimating ? 0 : 20)
        }
    }

    // MARK: - Apple Sign In Button

    private var appleSignInButton: some View {
        Button {
            Task { await handleAppleSignIn() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18, weight: .semibold))

                Text(mode == .signIn ? "Sign in with Apple" : "Sign up with Apple")
                    .font(FloTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.black)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .bounceOnTap()
    }

    // MARK: - Divider

    private var dividerRow: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(FloColors.Hex.border)
                .frame(height: 1)

            Text("or")
                .font(FloTypography.caption)
                .foregroundStyle(FloColors.Hex.textTertiary)

            Rectangle()
                .fill(FloColors.Hex.border)
                .frame(height: 1)
        }
    }

    // MARK: - Email Form

    private var emailForm: some View {
        VStack(spacing: 14) {
            if mode == .signUp {
                FloTextField(
                    placeholder: "Display name",
                    text: $displayName,
                    icon: "person"
                )
                .transition(FloAnimations.fadeScale)
            }

            FloTextField(
                placeholder: "Email",
                text: $email,
                icon: "envelope"
            )
            #if !os(macOS)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            #endif

            SecureFieldStyled(
                placeholder: "Password",
                text: $password
            )
        }
        .animation(FloAnimations.springDefault, value: mode)
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        FloButton(
            mode == .signIn ? "Sign In" : "Create Account",
            icon: mode == .signIn ? "arrow.right" : "person.badge.plus"
        ) {
            Task { await handleEmailAuth() }
        }
        .disabled(email.isEmpty || password.isEmpty)
        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
    }

    // MARK: - Toggle Mode

    private var toggleModeButton: some View {
        Button {
            withAnimation(FloAnimations.springDefault) {
                mode = mode == .signIn ? .signUp : .signIn
            }
        } label: {
            HStack(spacing: 4) {
                Text(mode == .signIn ? "Don't have an account?" : "Already have an account?")
                    .font(FloTypography.subheadline)
                    .foregroundStyle(FloColors.Hex.textSecondary)

                Text(mode == .signIn ? "Sign Up" : "Sign In")
                    .font(FloTypography.subheadline.weight(.semibold))
                    .foregroundStyle(FloColors.Hex.accent)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            FloCard {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(FloColors.Hex.accent)
                        .scaleEffect(1.2)

                    Text("Signing in...")
                        .font(FloTypography.callout)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
                .padding(8)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Actions

    private func handleAppleSignIn() async {
        do {
            let result = try await appleSignInDelegate.signIn()
            try await authManager.signInWithApple(
                idToken: result.idToken,
                nonce: result.nonce
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func handleEmailAuth() async {
        guard !email.isEmpty, !password.isEmpty else { return }

        do {
            switch mode {
            case .signIn:
                try await authManager.signInWithEmail(
                    email: email,
                    password: password
                )
            case .signUp:
                try await authManager.signUp(
                    email: email,
                    password: password,
                    displayName: displayName.isEmpty ? nil : displayName
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Secure Field Styled

private struct SecureFieldStyled: View {
    let placeholder: String
    @Binding var text: String
    @State private var isSecure = true
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .font(.system(size: 16))
                .foregroundStyle(isFocused ? FloColors.Hex.accent : FloColors.Hex.textTertiary)
                .animation(FloAnimations.easeFast, value: isFocused)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(FloTypography.body)
            .foregroundStyle(FloColors.Hex.textPrimary)
            .focused($isFocused)

            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .font(.system(size: 14))
                    .foregroundStyle(FloColors.Hex.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isFocused ? FloColors.Hex.accent : FloColors.Hex.border,
                    lineWidth: isFocused ? 2 : 1
                )
        )
        .animation(FloAnimations.easeFast, value: isFocused)
    }
}

// MARK: - Preview

#Preview {
    AuthView()
}
