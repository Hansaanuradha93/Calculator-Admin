import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)

                        VStack(spacing: 4) {
                            Text(viewModel.adminName)
                                .font(.system(size: 24, weight: .bold))

                            Text("System Administrator")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                    // Preferences
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Preferences")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                Text("Notifications")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding()

                            Divider().padding(.leading, 56)

                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                Text("Security")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        }
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }

                    // Log out
                    Button {
                        Task {
                            await viewModel.signOut()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                        }
                        .foregroundColor(.red)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.top, 16)

                }
                .padding()
            }
            .background(Color("BackgroundLight").ignoresSafeArea()) // Uses #f8f7f5
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
