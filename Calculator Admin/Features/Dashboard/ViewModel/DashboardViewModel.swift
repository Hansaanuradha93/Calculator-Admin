import Foundation
import Combine
import MapKit

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var devices: [Device] = []
    private var streamTask: Task<Void, Never>?

    private let deviceService: DeviceServiceProtocol

    init(deviceService: DeviceServiceProtocol = DeviceService()) {
        self.deviceService = deviceService
    }

    func loadDevices() {
        streamTask?.cancel()
        streamTask = Task {
            for await updatedDevices in deviceService.devicesStream() {
                self.devices = updatedDevices
            }
        }
    }
    
    func setWatchStatus(for deviceId: String, isWatching: Bool) {
        Task {
            do {
                try await deviceService.setWatchStatus(for: deviceId, isBeingWatched: isWatching)
            } catch {
                print("Error setting watch status: \(error)")
            }
        }
    }
    
    deinit {
        streamTask?.cancel()
    }
}
