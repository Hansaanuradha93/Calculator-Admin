import SwiftUI

struct AlertsView: View {
    @StateObject private var viewModel = AlertsViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.alerts) { alert in
                VStack(alignment: .leading, spacing: 5) {
                    Text(alert.message)
                        .font(.headline)
                    Text(alert.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Alerts")
            .task {
                await viewModel.loadAlerts()
            }
        }
    }
}
