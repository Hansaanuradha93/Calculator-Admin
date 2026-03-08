import Foundation
import Combine

@MainActor
class AlertsViewModel: ObservableObject {
    @Published var alerts: [Alert] = []

    private let alertService: AlertServiceProtocol

    init(alertService: AlertServiceProtocol = AlertService()) {
        self.alertService = alertService
    }

    func loadAlerts() async {
        do {
            alerts = try await alertService.fetchAlerts()
        } catch {
            print("Error loading alerts: \(error)")
        }
    }
}
