import Foundation

protocol AlertServiceProtocol {
    func fetchAlerts() async throws -> [Alert]
}

class AlertService: AlertServiceProtocol {
    func fetchAlerts() async throws -> [Alert] {
        return []
    }
}
