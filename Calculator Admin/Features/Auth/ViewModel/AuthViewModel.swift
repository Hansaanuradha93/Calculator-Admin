import Foundation
import Combine
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthServiceProtocol
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
        self.isAuthenticated = Auth.auth().currentUser != nil

        self.authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.isAuthenticated = user != nil
        }
    }

    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        do {
            isAuthenticated = try await authService.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        isLoading = true
        do {
            try await authService.signOut()
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
