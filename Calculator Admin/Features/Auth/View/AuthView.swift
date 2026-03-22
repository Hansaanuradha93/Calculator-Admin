import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.primaryOrange))
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
                }
                .padding(.bottom, 40)

                if viewModel.isLoading {
                    ProgressView()
                        .padding(.bottom, 20)
                }

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        Task { print("Sign with apple") }
                    } label: {
                        HStack(spacing: 12) {
                            Image(.appleLogo)
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Continue with Apple")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(Color.white))
                    }

                    Button {
                        Task { await viewModel.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 12) {
                            Image(.googleLogo)
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(Color(UIColor.systemBackground)))
                        .overlay(
                            Capsule()
                                .stroke(Color(UIColor.separator), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}
