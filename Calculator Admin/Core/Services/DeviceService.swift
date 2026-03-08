import Foundation

protocol DeviceServiceProtocol {
    func fetchDevices() async throws -> [Device]
    func fetchDevice(id: String) async throws -> Device
    func updateGeofence(for deviceId: String, radius: Double) async throws -> Geofence
}

class DeviceService: DeviceServiceProtocol {
    func fetchDevices() async throws -> [Device] {
        return []
    }

    func fetchDevice(id: String) async throws -> Device {
        return Device(id: id, name: "Sample iPhone", latitude: 37.7749, longitude: -122.4194, status: "Active")
    }

    func updateGeofence(for deviceId: String, radius: Double) async throws -> Geofence {
        return Geofence(id: UUID().uuidString, deviceId: deviceId, latitude: 0.0, longitude: 0.0, radius: radius)
    }
}
