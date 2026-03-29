import SwiftUI
import Combine

struct AlertsView: View {
    @StateObject private var viewModel = AlertsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.alerts) { alert in
                        alertRow(alert)
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("Alerts Feed")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadAlerts()
            }
        }
    }

    // MARK: - Alert Row

    @ViewBuilder
    private func alertRow(_ alert: Alert) -> some View {
        let config = alertStyle(for: alert)

        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(config.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: config.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(config.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(alert.message)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    if alert.priority == "high" {
                        Text("HIGH")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(.capsule)
                    }
                }

                HStack(spacing: 4) {
                    Text("Device: \(alert.deviceId)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(relativeTime(alert.timestamp))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(config.borderColor, lineWidth: config.borderWidth)
        )
        .cornerRadius(16)
        .shadow(color: config.shadowColor, radius: 5, x: 0, y: 2)
    }

    // MARK: - Alert Styling

    private struct AlertStyleConfig {
        let icon: String
        let color: Color
        let borderColor: Color
        let borderWidth: CGFloat
        let shadowColor: Color
    }

    private func alertStyle(for alert: Alert) -> AlertStyleConfig {
        switch (alert.type, alert.priority) {
        case ("arrival", "high"):
            // Home arrival — red accent
            return AlertStyleConfig(
                icon: "house.fill",
                color: .red,
                borderColor: .red.opacity(0.25),
                borderWidth: 1.5,
                shadowColor: .red.opacity(0.08)
            )
        case ("arrival", "low"):
            // Workplace arrival — blue/teal accent
            return AlertStyleConfig(
                icon: "briefcase.fill",
                color: .blue,
                borderColor: .clear,
                borderWidth: 0,
                shadowColor: .black.opacity(0.05)
            )
        case ("departure", _):
            // Left zone — orange warning
            return AlertStyleConfig(
                icon: "exclamationmark.triangle.fill",
                color: .orange,
                borderColor: .clear,
                borderWidth: 0,
                shadowColor: .black.opacity(0.05)
            )
        default:
            return AlertStyleConfig(
                icon: "bell.fill",
                color: .gray,
                borderColor: .clear,
                borderWidth: 0,
                shadowColor: .black.opacity(0.05)
            )
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}
