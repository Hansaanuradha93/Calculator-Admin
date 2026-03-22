import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var devices: [Device] = []
    private var streamTask: Task<Void, Never>?

    /// Tracks device IDs that this admin session has set to isBeingWatched = true
    private(set) var activelyWatchedDeviceIds: Set<String> = []

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
                print("[DashboardVM] ✅ Wrote isBeingWatched=\(isWatching) for device \(deviceId)")

                if isWatching {
                    activelyWatchedDeviceIds.insert(deviceId)
                } else {
                    activelyWatchedDeviceIds.remove(deviceId)
                }
            } catch {
                print("[DashboardVM] ❌ Error setting watch status: \(error)")
            }
        }
    }

    /// Resets ALL actively watched devices to isBeingWatched = false.
    /// Call this when the admin leaves the Map tab or the app goes to background.
    func resetAllWatchStatuses() {
        let idsToReset = activelyWatchedDeviceIds
        guard !idsToReset.isEmpty else { return }

        print("[DashboardVM] 🔄 Resetting isBeingWatched for \(idsToReset.count) device(s)")

        for deviceId in idsToReset {
            Task {
                do {
                    try await deviceService.setWatchStatus(for: deviceId, isBeingWatched: false)
                    print("[DashboardVM] ✅ Reset isBeingWatched=false for device \(deviceId)")
                } catch {
                    print("[DashboardVM] ❌ Error resetting watch: \(error)")
                }
            }
        }
        activelyWatchedDeviceIds.removeAll()
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
