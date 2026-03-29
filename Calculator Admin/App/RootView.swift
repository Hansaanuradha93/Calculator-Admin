import SwiftUI

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isLoading && !authViewModel.isAuthenticated {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).ignoresSafeArea())
            } else if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                AuthView(viewModel: authViewModel)
            }
        }
    }
}
