import Foundation
import Combine
import CoreLocation

@MainActor
class DeviceDetailViewModel: ObservableObject {
    @Published var device: Device?
    @Published var geofenceRadius: Double = 150.0
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    private var streamTask: Task<Void, Never>?

    private let deviceService: DeviceServiceProtocol

    init(deviceService: DeviceServiceProtocol = DeviceService()) {
        self.deviceService = deviceService
    }

    func loadDevice(id: String) {
        streamTask?.cancel()
        streamTask = Task {
            for await updatedDevice in deviceService.deviceStream(id: id) {
                self.device = updatedDevice
                if selectedCoordinate == nil {
                    selectedCoordinate = updatedDevice.coordinate
                }
            }
        }
    }

    func updateSafeZone(zoneType: String) {
        guard let deviceId = device?.id, let coord = selectedCoordinate else { return }
        
        let safeZone = SafeZone(
            latitude: coord.latitude,
            longitude: coord.longitude,
            radius: geofenceRadius
        )
        
        Task {
            do {
                try await deviceService.updateSafeZone(for: deviceId, zoneType: zoneType, safeZone: safeZone)
            } catch {
                print("Error updating \(zoneType): \(error)")
            }
        }
    }
    
    deinit {
        streamTask?.cancel()
    }
}
