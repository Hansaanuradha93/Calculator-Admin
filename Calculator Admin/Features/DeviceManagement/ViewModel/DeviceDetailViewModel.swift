import Foundation
import Combine

@MainActor
class DeviceDetailViewModel: ObservableObject {
    @Published var device: Device?
    @Published var geofenceRadius: Double = 100.0

    private let deviceService: DeviceServiceProtocol

    init(deviceService: DeviceServiceProtocol = DeviceService()) {
        self.deviceService = deviceService
    }

    func loadDevice(id: String) async {
        do {
            device = try await deviceService.fetchDevice(id: id)
        } catch {
            print("Error loading device: \(error)")
        }
    }

    func updateGeofence() async {
        guard let deviceId = device?.id else { return }
        do {
            _ = try await deviceService.updateGeofence(for: deviceId, radius: geofenceRadius)
        } catch {
            print("Error updating geofence: \(error)")
        }
    }
}
