import Foundation
import Combine

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

    // MARK: - Computed Counts

    var safeDeviceCount: Int {
        devices.filter { $0.currentSafeZone != nil && $0.currentSafeZone != "none" }.count
    }

    var liveTrackCount: Int {
        devices.filter { $0.currentSafeZone == "none" || $0.currentSafeZone == nil }.count
    }

    deinit {
        streamTask?.cancel()
    }
}
