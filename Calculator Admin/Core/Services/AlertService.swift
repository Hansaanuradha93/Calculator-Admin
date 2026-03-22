import Foundation
import FirebaseDatabase

protocol AlertServiceProtocol {
    func alertsStream() -> AsyncStream<[Alert]>
    func startMonitoring()
    func stopMonitoring()
}

class AlertService: AlertServiceProtocol {
    static let shared = AlertService()

    private let dbRef = Database.database().reference()
    private var previousZones: [String: String] = [:]
    private var isMonitoring = false
    private var mappingHandle: DatabaseHandle?

    private init() {}

    func startMonitoring() {
        if isMonitoring { return }
        isMonitoring = true
        mappingHandle = dbRef.child("locations").observe(.value) { [weak self] snapshot in
            guard let self = self, let dict = snapshot.value as? [String: [String: Any]] else { return }
            
            for (deviceId, deviceData) in dict {
                let currentZone = deviceData["currentSafeZone"] as? String ?? "none"
                let prevZone = self.previousZones[deviceId] ?? currentZone
                
                if (prevZone == "home" || prevZone == "workplace") && currentZone == "none" {
                    self.createAlert(for: deviceId, leftZone: prevZone)
                }
                
                self.previousZones[deviceId] = currentZone
            }
        }
    }
    
    func stopMonitoring() {
        if let handle = mappingHandle {
            dbRef.child("locations").removeObserver(withHandle: handle)
        }
        isMonitoring = false
    }

    private func createAlert(for deviceId: String, leftZone: String) {
        let alertId = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        let dict: [String: Any] = [
            "deviceId": deviceId,
            "message": "Device \(deviceId.prefix(6)) just left \(leftZone.capitalized)!",
            "timestamp": timestamp
        ]
        dbRef.child("alerts").child(alertId).setValue(dict)
    }

    func alertsStream() -> AsyncStream<[Alert]> {
        AsyncStream { continuation in
            let handle = dbRef.child("alerts").observe(.value) { snapshot in
                guard let dict = snapshot.value as? [String: [String: Any]] else {
                    continuation.yield([])
                    return
                }
                
                var alerts: [Alert] = []
                for (id, alertDict) in dict {
                    if let devId = alertDict["deviceId"] as? String,
                       let msg = alertDict["message"] as? String,
                       let ts = alertDict["timestamp"] as? Double {
                           alerts.append(Alert(id: id, deviceId: devId, message: msg, timestamp: Date(timeIntervalSince1970: ts)))
                    }
                }
                
                alerts.sort { $0.timestamp > $1.timestamp }
                continuation.yield(alerts)
            }
            continuation.onTermination = { @Sendable _ in
                self.dbRef.child("alerts").removeObserver(withHandle: handle)
            }
        }
    }
}
