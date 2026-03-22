import Combine
import CoreLocation

/// Google Places autocomplete using the Places API (New) REST endpoints.
/// Uses the same Google Maps API key from Info.plist.
@MainActor
class PlacesSearchService: ObservableObject {
    @Published var suggestions: [PlaceSuggestion] = []
    @Published var isSearching = false

    private var currentTask: Task<Void, Never>?

    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String ?? ""
    }

    private var bundleId: String {
        Bundle.main.bundleIdentifier ?? ""
    }

    func search(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            isSearching = false
            return
        }

        currentTask?.cancel()
        isSearching = true

        currentTask = Task {
            do {
                let results = try await fetchAutocomplete(query: trimmed)
                if !Task.isCancelled {
                    self.suggestions = results
                    self.isSearching = false
                }
            } catch {
                if !Task.isCancelled {
                    print("[PlacesSearch] Autocomplete error: \(error)")
                    self.isSearching = false
                }
            }
        }
    }

    func clearSuggestions() {
        suggestions = []
        isSearching = false
        currentTask?.cancel()
    }

    /// Resolves a place suggestion to coordinates using Place Details.
    func resolve(_ suggestion: PlaceSuggestion) async -> CLLocationCoordinate2D? {
        do {
            return try await fetchPlaceDetails(placeId: suggestion.placeId)
        } catch {
            print("[PlacesSearch] Place details error: \(error)")
            return nil
        }
    }

    // MARK: - Google Places API (New) Requests

    private func fetchAutocomplete(query: String) async throws -> [PlaceSuggestion] {
        let url = URL(string: "https://places.googleapis.com/v1/places:autocomplete")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(bundleId, forHTTPHeaderField: "X-Ios-Bundle-Identifier")

        let body: [String: Any] = [
            "input": query,
            "languageCode": "en"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        // Debug: log HTTP status and raw response
        if let httpResponse = response as? HTTPURLResponse {
            print("[PlacesSearch] Autocomplete HTTP status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                let raw = String(data: data, encoding: .utf8) ?? "no body"
                print("[PlacesSearch] Error response: \(raw)")
                return []
            }
        }

        let decoded = try JSONDecoder().decode(AutocompleteResponse.self, from: data)

        let results = decoded.suggestions?.compactMap { item -> PlaceSuggestion? in
            guard let prediction = item.placePrediction else { return nil }
            return PlaceSuggestion(
                placeId: prediction.placeId,
                title: prediction.structuredFormat?.mainText?.text ?? prediction.text?.text ?? "",
                subtitle: prediction.structuredFormat?.secondaryText?.text ?? ""
            )
        } ?? []

        print("[PlacesSearch] Found \(results.count) suggestions for '\(query)'")
        return results
    }

    private func fetchPlaceDetails(placeId: String) async throws -> CLLocationCoordinate2D? {
        let urlString = "https://places.googleapis.com/v1/places/\(placeId)"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(bundleId, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        request.setValue("location", forHTTPHeaderField: "X-Goog-FieldMask")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let raw = String(data: data, encoding: .utf8) ?? "no body"
            print("[PlacesSearch] Place details error: \(raw)")
            return nil
        }

        let decoded = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)

        guard let loc = decoded.location else { return nil }
        print("[PlacesSearch] Resolved place to: \(loc.latitude), \(loc.longitude)")
        return CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
    }
}

// MARK: - Model

struct PlaceSuggestion: Identifiable {
    let id = UUID()
    let placeId: String
    let title: String
    let subtitle: String
}

// MARK: - API Response Models

private struct AutocompleteResponse: Decodable {
    let suggestions: [SuggestionItem]?
}

private struct SuggestionItem: Decodable {
    let placePrediction: PlacePrediction?
}

private struct PlacePrediction: Decodable {
    let placeId: String
    let text: FormattedText?
    let structuredFormat: StructuredFormat?
}

private struct StructuredFormat: Decodable {
    let mainText: FormattedText?
    let secondaryText: FormattedText?
}

private struct FormattedText: Decodable {
    let text: String?
}

private struct PlaceDetailsResponse: Decodable {
    let location: LatLng?
}

private struct LatLng: Decodable {
    let latitude: Double
    let longitude: Double
}
