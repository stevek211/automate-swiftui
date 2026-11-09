import AuthenticationServices
import CryptoKit
import Foundation

struct AppleSignInResult {
    let idToken: String
    let nonce: String
    let fullName: PersonNameComponents?
}

class AppleSignInHelper: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    private var currentNonce: String?

    func performSignIn() async throws -> AppleSignInResult {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let nonce = randomNonceString()
            currentNonce = nonce

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              let nonce = currentNonce else {
            continuation?.resume(throwing: NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get Apple ID token"]))
            continuation = nil
            return
        }

        let result = AppleSignInResult(
            idToken: idToken,
            nonce: nonce,
            fullName: credential.fullName
        )
        continuation?.resume(returning: result)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Prefer an existing foreground-active window if available
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) {
            if let window = windowScene.keyWindow
                ?? windowScene.windows.first(where: { !$0.isHidden })
                ?? windowScene.windows.first {
                return window
            }
            // Fallback: create a window bound to the scene (avoid deprecated init())
            let window = UIWindow(windowScene: windowScene)
            // Ensure it has a rootViewController so it can act as a valid presentation anchor
            if window.rootViewController == nil {
                window.rootViewController = UIViewController()
            }
            return window
        }
        // If no active scene is available, try any connected window scene
        if let anyScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            let window = UIWindow(windowScene: anyScene)
            if window.rootViewController == nil {
                window.rootViewController = UIViewController()
            }
            return window
        }
        // Ultimate fallback: create a temporary window using a new window scene when possible
        // Note: Returning an empty ASPresentationAnchor can cause presentation failures.
        // As a last resort, provide a dummy window not attached to UI (still requires a scene on modern iOS).
        let tempWindow = UIWindow()
        if tempWindow.rootViewController == nil {
            tempWindow.rootViewController = UIViewController()
        }
        return tempWindow
    }

    // MARK: - Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
