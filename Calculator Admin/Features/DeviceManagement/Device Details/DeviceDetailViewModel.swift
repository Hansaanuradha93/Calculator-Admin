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
    @Published var showSaveConfirmation = false
    @Published var savedZoneType: String?

    let placesService = PlacesSearchService()

    private var streamTask: Task<Void, Never>?
    private var searchDebounce: AnyCancellable?
    private let deviceService: DeviceServiceProtocol

    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String ?? ""
    }

    init(deviceService: DeviceServiceProtocol = DeviceService()) {
        self.deviceService = deviceService
        setupSearchDebounce()
    }

    // MARK: - Live Search Debounce

    private func setupSearchDebounce() {
        searchDebounce = $addressQuery
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.placesService.search(query: query)
            }
    }

    // MARK: - Place Selection

    func selectSuggestion(_ suggestion: PlaceSuggestion) {
        addressQuery = suggestion.title
        resolvedAddress = [suggestion.title, suggestion.subtitle]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        placesService.clearSuggestions()

        Task {
            if let coordinate = await placesService.resolve(suggestion) {
                selectedCoordinate = coordinate
            }
        }
    }

    // MARK: - Device Loading

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

    // MARK: - Reverse Geocoding (Google Geocoding API)

    func onMapCoordinateChanged(_ coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        reverseGeocode(coordinate)
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        Task {
            let lat = coordinate.latitude
            let lng = coordinate.longitude
            let urlString = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(lat),\(lng)&key=\(apiKey)"

            guard let url = URL(string: urlString) else { return }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)

                if let firstResult = response.results.first {
                    self.resolvedAddress = firstResult.formattedAddress
                }
            } catch {
                print("Reverse geocode error: \(error.localizedDescription)")
            }
        }
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

    // MARK: - Radius Helpers

    var formattedRadius: String {
        if geofenceRadius >= 1000 {
            return String(format: "%.1f km", geofenceRadius / 1000)
        }
        return String(format: "%.0f m", geofenceRadius)
    }

    deinit {
        streamTask?.cancel()
        searchDebounce?.cancel()
    }
}

// MARK: - Google Geocoding Response Models

private struct GeocodingResponse: Decodable {
    let results: [GeocodingResult]
}

private struct GeocodingResult: Decodable {
    let formattedAddress: String

    enum CodingKeys: String, CodingKey {
        case formattedAddress = "formatted_address"
    }
}
