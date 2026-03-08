import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        ZStack {
            Color("BackgroundLight") // Need to define #f8f7f5 or use standard SystemGroupedBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.orange) // #ff9d0a
                            .frame(width: 64, height: 64)
                            .shadow(color: Color.orange.opacity(0.2), radius: 10, x: 0, y: 5)

                        Image(systemName: "square.grid.2x2.fill") // Dashboard icon
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.bottom, 16)

                    Text("Welcome Back")
                        .font(.system(size: 30, weight: .bold, design: .default))
                        .foregroundColor(.primary)

                    Text("Please enter your details to sign in")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)

                if viewModel.isLoading {
                    ProgressView()
                        .padding(.bottom, 20)
                }

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        Task { await viewModel.signInWithApple() }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20))
                            Text("Continue with Apple")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(12)
                    }

                    Button {
                        Task { await viewModel.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 12) {
                            // Using standard SF symbol since we don't have the Google SVG asset yet
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue) // Simple alternative for Google logo
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(UIColor.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(UIColor.separator), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.top, 20)
                }
            }
        }
    }
}
