import SwiftUI
import Supabase
import Auth
import AuthenticationServices

/// User model exposed to the rest of the app
struct LocalUser: Codable, Equatable {
    let id: UUID
    var name: String
    var email: String
    var authProvider: AuthProvider

    enum AuthProvider: String, Codable {
        case email
        case apple
        case google
    }

    init(id: UUID, name: String, email: String, authProvider: AuthProvider) {
        self.id = id
        self.name = name
        self.email = email
        self.authProvider = authProvider
    }

    init(from supabaseUser: User) {
        self.id = supabaseUser.id
        self.name = supabaseUser.userMetadata["full_name"]?.stringValue ?? "User"
        self.email = supabaseUser.email ?? ""

        let provider = supabaseUser.appMetadata["provider"]?.stringValue ?? "email"
        switch provider {
        case "apple": self.authProvider = .apple
        case "google": self.authProvider = .google
        default: self.authProvider = .email
        }
    }
}

@Observable
class AuthState {
    var currentUser: LocalUser? = nil
    var isLoading = true

    var isAuthenticated: Bool { currentUser != nil }

    private var authStateTask: Task<Void, Never>?
    private var appleSignInHelper: AppleSignInHelper?

    init() {
        // Restore session synchronously is not possible; we'll rely on authStateChanges
        isLoading = true

        // Listen for auth state changes
        authStateTask = Task { [weak self] in
            for await (event, session) in SupabaseManager.client.auth.authStateChanges {
                guard let self else { return }
                await MainActor.run {
                    switch event {
                    case .signedIn, .tokenRefreshed, .userUpdated:
                        if let session {
                            self.currentUser = LocalUser(from: session.user)
                        }
                    case .signedOut:
                        self.currentUser = nil
                    default:
                        break
                    }
                    self.isLoading = false
                }
            }
        }
    }

    deinit {
        authStateTask?.cancel()
    }

    // MARK: - Dev Bypass

    /// Skip auth entirely for development — uses a fixed local user, no Supabase call.
    func devBypass() {
        let devUser = LocalUser(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Dev User",
            email: "dev@autoguard.test",
            authProvider: .email
        )
        currentUser = devUser
        isLoading = false
    }

    // MARK: - Sign Up

    func signUp(name: String, email: String, password: String) async -> (success: Bool, error: String?) {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            return (false, "Please enter your name")
        }
        guard !normalizedEmail.isEmpty else {
            return (false, "Please enter your email")
        }
        guard password.count >= 6 else {
            return (false, "Password must be at least 6 characters")
        }

        do {
            try await SupabaseManager.client.auth.signUp(
                email: normalizedEmail,
                password: password,
                data: ["full_name": .string(trimmedName)]
            )
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    // MARK: - Log In

    func logIn(email: String, password: String) async -> (success: Bool, error: String?) {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)

        guard !normalizedEmail.isEmpty else {
            return (false, "Please enter your email")
        }
        guard password.count >= 6 else {
            return (false, "Password must be at least 6 characters")
        }

        do {
            try await SupabaseManager.client.auth.signIn(
                email: normalizedEmail,
                password: password
            )
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    // MARK: - Apple Sign In

    func signInWithApple() async -> (success: Bool, error: String?) {
        do {
            let helper = AppleSignInHelper()
            self.appleSignInHelper = helper // retain during async operation
            let result = try await helper.performSignIn()
            self.appleSignInHelper = nil

            try await SupabaseManager.client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: result.idToken,
                    nonce: result.nonce
                )
            )

            // Update name if Apple provided it (only on first sign-in)
            if let fullName = result.fullName {
                let name = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                if !name.isEmpty {
                    _ = try? await SupabaseManager.client.auth.update(
                        user: UserAttributes(data: ["full_name": .string(name)])
                    )
                }
            }

            return (true, nil)
        } catch {
            self.appleSignInHelper = nil
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                return (false, nil) // user cancelled, no error message
            }
            return (false, error.localizedDescription)
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async -> (success: Bool, error: String?) {
        do {
            try await SupabaseManager.client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "com.automate.app://auth-callback")
            )
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    // MARK: - Log Out

    func logOut() async {
        try? await SupabaseManager.client.auth.signOut()
        currentUser = nil
    }

    // MARK: - Delete Account

    func deleteAccount() async -> (success: Bool, error: String?) {
        // Note: Full user deletion requires a server-side Edge Function with service role key.
        // For now, we sign the user out. To fully delete, create a Supabase Edge Function.
        await logOut()
        return (true, nil)
    }

    // MARK: - Update Profile

    func updateName(_ newName: String) async {
        do {
            try await SupabaseManager.client.auth.update(
                user: UserAttributes(data: ["full_name": .string(newName)])
            )
            if var user = currentUser {
                user.name = newName
                currentUser = user
            }
        } catch {
            // Silently fail — name update is non-critical
        }
    }
}
