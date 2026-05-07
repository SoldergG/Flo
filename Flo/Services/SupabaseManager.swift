import Foundation
import Supabase
import AuthenticationServices
import CryptoKit

// MARK: - Supabase Manager

@MainActor @Observable
final class SupabaseManager {
    // MARK: - Singleton

    static let shared = SupabaseManager()

    // MARK: - Supabase Client

    let client: SupabaseClient

    // MARK: - Auth State

    var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
    var isLoading: Bool = false
    var authError: String?

    // MARK: - Init

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://bnwzzddfeikgtyoycteu.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJud3p6ZGRmZWlrZ3R5b3ljdGV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwOTQzNjksImV4cCI6MjA5MzY3MDM2OX0.H_n2j5O2ic9drrgZMLDh-JVTx2CZCvFuJMHvVIIOKgc"
        )

        Task { await restoreSession() }
    }

    // MARK: - Session Restoration

    private func restoreSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await client.auth.session
            currentUser = session.user
        } catch {
            currentUser = nil
        }
    }

    // MARK: - Observe Auth Changes

    func observeAuthChanges() async {
        for await (event, session) in client.auth.authStateChanges {
            await MainActor.run {
                switch event {
                case .signedIn, .tokenRefreshed, .userUpdated:
                    self.currentUser = session?.user
                case .signedOut:
                    self.currentUser = nil
                default:
                    break
                }
            }
        }
    }

    // MARK: - Sign In with Apple

    func signInWithApple(idToken: String, nonce: String) async throws {
        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            await MainActor.run {
                self.currentUser = session.user
            }
        } catch {
            await MainActor.run {
                self.authError = error.localizedDescription
            }
            throw error
        }
    }

    // MARK: - Email Sign In

    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            await MainActor.run {
                self.currentUser = session.user
            }
        } catch {
            await MainActor.run {
                self.authError = error.localizedDescription
            }
            throw error
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, displayName: String? = nil) async throws {
        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            var userData: [String: AnyJSON]? = nil
            if let displayName {
                userData = ["display_name": .string(displayName)]
            }

            let result = try await client.auth.signUp(
                email: email,
                password: password,
                data: userData
            )
            await MainActor.run {
                self.currentUser = result.user
            }
        } catch {
            await MainActor.run {
                self.authError = error.localizedDescription
            }
            throw error
        }
    }

    // MARK: - Sign Out

    func signOut() async throws {
        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            try await client.auth.signOut()
            await MainActor.run {
                self.currentUser = nil
            }
        } catch {
            await MainActor.run {
                self.authError = error.localizedDescription
            }
            throw error
        }
    }

    // MARK: - Get Current User

    func getCurrentUser() async -> User? {
        do {
            let user = try await client.auth.session.user
            await MainActor.run {
                self.currentUser = user
            }
            return user
        } catch {
            return nil
        }
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        guard let userId = currentUser?.id else { return }

        try await client.from("profiles")
            .delete()
            .eq("id", value: userId.uuidString)
            .execute()

        try await signOut()
    }

    // MARK: - Update Profile

    func updateProfile(displayName: String) async throws {
        try await client.auth.update(
            user: UserAttributes(
                data: ["display_name": .string(displayName)]
            )
        )
    }
}

// MARK: - Apple Sign In Helper

final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<(idToken: String, nonce: String), Error>?
    private var currentNonce: String?

    func signIn() async throws -> (idToken: String, nonce: String) {
        let nonce = try Self.randomNonceString()
        currentNonce = nonce

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(nonce)

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let idTokenData = appleIDCredential.identityToken,
              let idToken = String(data: idTokenData, encoding: .utf8),
              let nonce = currentNonce else {
            continuation?.resume(throwing: FloAuthError.invalidCredentials)
            return
        }

        continuation?.resume(returning: (idToken: idToken, nonce: nonce))
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(macOS)
        return NSApplication.shared.keyWindow ?? NSWindow()
        #else
        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first else {
            return UIWindow()
        }
        return window
        #endif
    }

    // MARK: - Nonce Helpers

    enum NonceError: Error {
        case generationFailed(OSStatus)
    }

    static func randomNonceString(length: Int = 32) throws -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else {
            throw NonceError.generationFailed(errorCode)
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Auth Error

enum FloAuthError: LocalizedError {
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials received from Apple Sign In."
        }
    }
}
