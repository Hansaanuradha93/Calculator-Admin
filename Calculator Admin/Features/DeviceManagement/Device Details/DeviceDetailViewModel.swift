import Foundation
import Combine
import CoreLocation

// MARK: - Zone Type

enum ZoneType: String, CaseIterable, Identifiable {
    case home
    case workplace

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home: return "Home"
        case .workplace: return "Workplace"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .workplace: return "building.2.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .home: return .green
        case .workplace: return .orange
        }
    }
}

import SwiftUI

// MARK: - Per-Zone State

@MainActor
class ZoneEditorState: ObservableObject {
    let zoneType: ZoneType

    @Published var coordinate: CLLocationCoordinate2D?
    @Published var radius: Double = 150.0
    @Published var addressQuery = ""
    @Published var resolvedAddress = ""
    @Published var isConfigured = false

    /// Prevents overwriting user edits on subsequent stream updates
    private var hasLoaded = false

    init(zoneType: ZoneType) {
        self.zoneType = zoneType
    }

    /// Load existing safe zone data from a device (only on first load)
    /// Returns the coordinate if an existing zone was loaded (for reverse geocoding)
    @discardableResult
    func loadFromDevice(_ device: Device) -> CLLocationCoordinate2D? {
        guard !hasLoaded else { return nil }
        hasLoaded = true

        let existingZone: SafeZone? = zoneType == .home ? device.home : device.workplace

        if let zone = existingZone {
            coordinate = zone.coordinate
            radius = zone.radius
            isConfigured = true
            return zone.coordinate
        } else {
            coordinate = device.coordinate
            isConfigured = false
            return nil
        }
    }

    var formattedRadius: String {
        if radius >= 1000 {
            return String(format: "%.1f km", radius / 1000)
        }
        return String(format: "%.0f m", radius)
    }
}

// MARK: - ViewModel

@MainActor
class DeviceDetailViewModel: ObservableObject {
    @Published var device: Device?
    @Published var selectedZoneType: ZoneType = .home
    @Published var showSaveConfirmation = false
    @Published var savedZoneType: String?

    let homeZone = ZoneEditorState(zoneType: .home)
    let workZone = ZoneEditorState(zoneType: .workplace)
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

    /// The currently active zone editor based on the selected tab
    var activeZone: ZoneEditorState {
        selectedZoneType == .home ? homeZone : workZone
    }

    // MARK: - Live Search Debounce

    private func setupSearchDebounce() {
        // We observe the active zone's address query
        searchDebounce = $selectedZoneType
            .combineLatest(homeZone.$addressQuery, workZone.$addressQuery)
            .map { type, homeQuery, workQuery in
                type == .home ? homeQuery : workQuery
            }
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.placesService.search(query: query)
            }
    }

    // MARK: - Place Selection

    func selectSuggestion(_ suggestion: PlaceSuggestion) {
        let zone = activeZone
        zone.addressQuery = suggestion.title
        zone.resolvedAddress = [suggestion.title, suggestion.subtitle]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        placesService.clearSuggestions()

        Task {
            if let coordinate = await placesService.resolve(suggestion) {
                zone.coordinate = coordinate
            }
        }
    }

    // MARK: - Device Loading

    func loadDevice(id: String) {
        streamTask?.cancel()
        streamTask = Task {
            for await updatedDevice in deviceService.deviceStream(id: id) {
                self.device = updatedDevice

                // Load existing zones from Firebase (only on first update)
                if let homeCoord = homeZone.loadFromDevice(updatedDevice) {
                    reverseGeocode(homeCoord, for: homeZone)
                }
                if let workCoord = workZone.loadFromDevice(updatedDevice) {
                    reverseGeocode(workCoord, for: workZone)
                }
            }
        }
    }

    // MARK: - Map Coordinate Changed (user tapped or dragged)

    func onMapCoordinateChanged(_ coordinate: CLLocationCoordinate2D) {
        activeZone.coordinate = coordinate
        reverseGeocode(coordinate, for: activeZone)
    }

    // MARK: - Reverse Geocoding (Google API)

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D, for zone: ZoneEditorState) {
        Task {
            let lat = coordinate.latitude
            let lng = coordinate.longitude
            let urlString = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(lat),\(lng)&key=\(apiKey)"

            guard let url = URL(string: urlString) else { return }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)

                if let firstResult = response.results.first {
                    zone.resolvedAddress = firstResult.formattedAddress
                }
            } catch {
                print("Reverse geocode error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Save Safe Zone

    func saveActiveZone() {
        let zone = activeZone
        guard let deviceId = device?.id, let coord = zone.coordinate else { return }

        let safeZone = SafeZone(
            latitude: coord.latitude,
            longitude: coord.longitude,
            radius: zone.radius
        )

        Task {
            do {
                try await deviceService.updateSafeZone(for: deviceId, zoneType: zone.zoneType.rawValue, safeZone: safeZone)
                savedZoneType = zone.zoneType.label
                showSaveConfirmation = true
            } catch {
                print("Error updating \(zone.zoneType.rawValue): \(error)")
            }
        }
    }

    deinit {
        streamTask?.cancel()
        searchDebounce?.cancel()
    }
}

// MARK: - Google Geocoding Response

private struct GeocodingResponse: Decodable {
    let results: [GeocodingResult]
}

private struct GeocodingResult: Decodable {
    let formattedAddress: String

    enum CodingKeys: String, CodingKey {
        case formattedAddress = "formatted_address"
    }
}
