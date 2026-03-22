import Foundation
import Combine
import CoreLocation

@MainActor
class DeviceDetailViewModel: ObservableObject {
    @Published var device: Device?
    @Published var geofenceRadius: Double = 150.0
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    @Published var addressQuery = ""
    @Published var resolvedAddress = ""
    @Published var isGeocodingLoading = false
    @Published var showSaveConfirmation = false
    @Published var savedZoneType: String?
    
    private var streamTask: Task<Void, Never>?
    private let deviceService: DeviceServiceProtocol
    private let geocoder = CLGeocoder()

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
                    reverseGeocode(updatedDevice.coordinate)
                }
            }
        }
    }
    
    // MARK: - Geocoding
    
    func searchAddress() {
        let query = addressQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        isGeocodingLoading = true
        geocoder.cancelGeocode()
        
        geocoder.geocodeAddressString(query) { [weak self] placemarks, error in
            Task { @MainActor in
                guard let self else { return }
                self.isGeocodingLoading = false
                
                if let placemark = placemarks?.first, let location = placemark.location {
                    self.selectedCoordinate = location.coordinate
                    self.resolvedAddress = [
                        placemark.name,
                        placemark.locality,
                        placemark.administrativeArea
                    ]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                }
            }
        }
    }
    
    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            Task { @MainActor in
                guard let self else { return }
                if let placemark = placemarks?.first {
                    self.resolvedAddress = [
                        placemark.name,
                        placemark.locality,
                        placemark.administrativeArea
                    ]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                }
            }
        }
    }
    
    func onMapCoordinateChanged(_ coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        reverseGeocode(coordinate)
    }

    // MARK: - Safe Zone

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
                savedZoneType = zoneType
                showSaveConfirmation = true
            } catch {
                print("Error updating \(zoneType): \(error)")
            }
        }
    }
    
    // MARK: - Radius helpers
    
    var formattedRadius: String {
        if geofenceRadius >= 1000 {
            return String(format: "%.1f km", geofenceRadius / 1000)
        }
        return String(format: "%.0f m", geofenceRadius)
    }
    
    deinit {
        streamTask?.cancel()
    }
}
