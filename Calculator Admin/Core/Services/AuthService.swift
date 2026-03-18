import Foundation
import FirebaseCore
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn

protocol AuthServiceProtocol {
    func signInWithGoogle() async throws -> Bool
    func signOut() async throws
}

class AuthService: NSObject, AuthServiceProtocol {
    // --- Google Sign-In ---
    @MainActor
    func signInWithGoogle() async throws -> Bool {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw URLError(.cannotFindHost)
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw URLError(.cannotFindHost)
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = result.user

        guard let idToken = user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }

        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: user.accessToken.tokenString)
        let authResult = try await Auth.auth().signIn(with: credential)
        return authResult.user.uid.isEmpty == false
    }

    // --- Sign Out ---
    func signOut() async throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }
}
