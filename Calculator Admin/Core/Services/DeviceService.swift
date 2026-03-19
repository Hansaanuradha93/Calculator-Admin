import Foundation
import FirebaseDatabase

protocol DeviceServiceProtocol {
    func devicesStream() -> AsyncStream<[Device]>
    func deviceStream(id: String) -> AsyncStream<Device>
    func updateSafeZone(for deviceId: String, zoneType: String, safeZone: SafeZone) async throws
    func setWatchStatus(for deviceId: String, isBeingWatched: Bool) async throws
}

class DeviceService: DeviceServiceProtocol {
    private let dbRef = Database.database().reference()
    
    func devicesStream() -> AsyncStream<[Device]> {
        AsyncStream { continuation in
            let handle = dbRef.child("locations").observe(.value) { snapshot in
                guard let dict = snapshot.value as? [String: [String: Any]] else {
                    continuation.yield([])
                    return
                }
                let devices = dict.compactMap { (id, deviceDict) -> Device? in
                    self.parseDevice(id: id, dict: deviceDict)
                }
                continuation.yield(devices)
            }
            continuation.onTermination = { @Sendable _ in
                self.dbRef.child("locations").removeObserver(withHandle: handle)
            }
        }
    }
    
    func deviceStream(id: String) -> AsyncStream<Device> {
        AsyncStream { continuation in
            let handle = dbRef.child("locations").child(id).observe(.value) { snapshot in
                guard let dict = snapshot.value as? [String: Any] else { return }
                continuation.yield(self.parseDevice(id: id, dict: dict))
            }
            continuation.onTermination = { @Sendable _ in
                self.dbRef.child("locations").child(id).removeObserver(withHandle: handle)
            }
        }
    }
    
    func updateSafeZone(for deviceId: String, zoneType: String, safeZone: SafeZone) async throws {
        let nodeRef = dbRef.child("locations").child(deviceId).child(zoneType)
        let dict: [String: Any] = [
            "latitude": safeZone.latitude,
            "longitude": safeZone.longitude,
            "radius": safeZone.radius
        ]
        try await nodeRef.setValue(dict)
    }
    
    func setWatchStatus(for deviceId: String, isBeingWatched: Bool) async throws {
        try await dbRef.child("locations").child(deviceId).child("isBeingWatched").setValue(isBeingWatched)
    }
    
    private func parseDevice(id: String, dict: [String: Any]) -> Device {
        var device = Device(id: id)
        device.latitude = dict["latitude"] as? Double
        device.longitude = dict["longitude"] as? Double
        device.timestamp = dict["timestamp"] as? Double
        device.currentSafeZone = dict["currentSafeZone"] as? String
        device.isBeingWatched = dict["isBeingWatched"] as? Bool
        
        if let homeDict = dict["home"] as? [String: Any],
           let lat = homeDict["latitude"] as? Double,
           let lon = homeDict["longitude"] as? Double,
           let rad = homeDict["radius"] as? Double {
               device.home = SafeZone(latitude: lat, longitude: lon, radius: rad)
        }
        
        if let workDict = dict["workplace"] as? [String: Any],
           let lat = workDict["latitude"] as? Double,
           let lon = workDict["longitude"] as? Double,
           let rad = workDict["radius"] as? Double {
               device.workplace = SafeZone(latitude: lat, longitude: lon, radius: rad)
        }
        
        return device
    }
}
