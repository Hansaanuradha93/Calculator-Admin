import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var adminName: String = "Admin"

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }

    func signOut() async {
        do {
            try await authService.signOut()
        } catch {
            print("Error logging out: \(error)")
        }
    }
}
