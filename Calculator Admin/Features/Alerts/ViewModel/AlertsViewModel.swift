import Foundation
import Combine

@MainActor
class AlertsViewModel: ObservableObject {
    @Published var alerts: [Alert] = []
    private var streamTask: Task<Void, Never>?

    private let alertService: AlertServiceProtocol

    init(alertService: AlertServiceProtocol = AlertService()) {
        self.alertService = alertService
    }

    func loadAlerts() {
        alertService.startMonitoring()
        streamTask?.cancel()
        streamTask = Task {
            for await updatedAlerts in alertService.alertsStream() {
                self.alerts = updatedAlerts
            }
        }
    }
    
    deinit {
        streamTask?.cancel()
        alertService.stopMonitoring()
    }
}
