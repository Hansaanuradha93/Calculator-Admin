import Foundation
import CoreLocation

struct SafeZone: Codable, Equatable, Hashable {
    var latitude: Double
    var longitude: Double
    var radius: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Device: Identifiable, Codable, Hashable, Equatable {
    var id: String
    var latitude: Double?
    var longitude: Double?
    var timestamp: Double?
    var currentSafeZone: String?
    var isBeingWatched: Bool?

    var home: SafeZone?
    var workplace: SafeZone?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude ?? 0.0, longitude: longitude ?? 0.0)
    }
    
    var name: String {
        return "Device: \(id.prefix(6))"
    }
    
    var status: String {
        if let currentSafeZone = currentSafeZone, currentSafeZone != "none" {
            return "Safe (\(currentSafeZone.capitalized))"
        }
        return "Live Track"
    }
    
    // For Equatable
    static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.id == rhs.id && 
               lhs.latitude == rhs.latitude && 
               lhs.longitude == rhs.longitude &&
               lhs.currentSafeZone == rhs.currentSafeZone &&
               lhs.isBeingWatched == rhs.isBeingWatched
    }
}

struct Alert: Identifiable, Codable, Equatable {
    var id: String
    var deviceId: String
    var message: String
    var timestamp: Date
    var priority: String    // "high", "low", "normal"
    var type: String        // "arrival", "departure"
}

struct AdminUser: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
}
