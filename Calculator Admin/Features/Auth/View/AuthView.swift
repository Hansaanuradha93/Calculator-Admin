import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Admin Login")
                .font(.largeTitle)
                .bold()

            if viewModel.isLoading {
                ProgressView()
            }

            Button("Sign in with Apple") {
                Task {
                    await viewModel.signInWithApple()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Sign in with Google") {
                Task {
                    await viewModel.signInWithGoogle()
                }
            }
            .buttonStyle(.bordered)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}
