import Foundation
import CoreLocation

struct Device: Identifiable, Codable, Hashable, Equatable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let status: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Alert: Identifiable, Codable {
    let id: String
    let deviceId: String
    let message: String
    let timestamp: Date
}

struct Geofence: Identifiable, Codable {
    let id: String
    let deviceId: String
    let latitude: Double
    let longitude: Double
    let radius: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct AdminUser: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
}
