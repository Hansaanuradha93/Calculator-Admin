import SwiftUI
import Combine

struct AlertsView: View {
    @StateObject private var viewModel = AlertsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.alerts) { alert in
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.orange)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(alert.message)
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .foregroundColor(.primary)

                                HStack(spacing: 4) {
                                    Text("Device: \(alert.deviceId)")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(alert.timestamp, style: .relative)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding()
            }
            .background(Color("BackgroundLight").ignoresSafeArea()) // Uses #f8f7f5
            .navigationTitle("Alerts Feed")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadAlerts()
            }
        }
    }
}
