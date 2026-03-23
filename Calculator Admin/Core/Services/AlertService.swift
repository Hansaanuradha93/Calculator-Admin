import Foundation
import FirebaseDatabase
import UserNotifications

// NSNotification name for in-app UI reaction
extension Notification.Name {
    static let deviceArrivedHome = Notification.Name("deviceArrivedHome")
    static let deviceArrivedWorkplace = Notification.Name("deviceArrivedWorkplace")
}

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

    // MARK: - Notification Permissions

    func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("[AlertService] ❌ Notification permission error: \(error)")
            } else {
                print("[AlertService] ✅ Notification permission granted: \(granted)")
            }
        }
    }

    // MARK: - Zone Monitoring

    func startMonitoring() {
        if isMonitoring { return }
        isMonitoring = true

        mappingHandle = dbRef.child("locations").observe(.value) { [weak self] snapshot in
            guard let self = self, let dict = snapshot.value as? [String: [String: Any]] else { return }

            for (deviceId, deviceData) in dict {
                let currentZone = deviceData["currentSafeZone"] as? String ?? "none"
                let prevZone = self.previousZones[deviceId] ?? currentZone

                // Skip if no change
                if prevZone == currentZone {
                    self.previousZones[deviceId] = currentZone
                    continue
                }

                // --- HANDLE DEPARTURES ---
                if prevZone == "home" {
                    // Left Home
                    self.createDepartureAlert(for: deviceId, leftZone: "home", priority: "low")
                    self.sendLocalNotification(
                        title: "🏠 Left Home",
                        body: "Device \(deviceId.prefix(6)) just left home.",
                        isHighPriority: false
                    )
                } else if prevZone == "workplace" {
                    // Left Workplace
                    self.createDepartureAlert(for: deviceId, leftZone: "workplace", priority: "high")
                    self.sendLocalNotification(
                        title: "💼 Left Workplace",
                        body: "Device \(deviceId.prefix(6)) just left the workplace.",
                        isHighPriority: true
                    )
                }

                // --- HANDLE ARRIVALS ---
                if currentZone == "home" {
                    // Arrived Home
                    self.createArrivalAlert(for: deviceId, arrivedAt: "Home", priority: "high")
                    self.sendLocalNotification(
                        title: "🏠 Home Arrival",
                        body: "Device \(deviceId.prefix(6)) just arrived at home.",
                        isHighPriority: true
                    )
                    NotificationCenter.default.post(name: .deviceArrivedHome, object: deviceId)
                } else if currentZone == "workplace" {
                    // Arrived Workplace
                    self.createArrivalAlert(for: deviceId, arrivedAt: "Workplace", priority: "low")
                    self.sendLocalNotification(
                        title: "💼 Workplace Arrival",
                        body: "Device \(deviceId.prefix(6)) arrived at workplace.",
                        isHighPriority: false
                    )
                    NotificationCenter.default.post(name: .deviceArrivedWorkplace, object: deviceId)
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

    // MARK: - Alert Creation

    private func createDepartureAlert(for deviceId: String, leftZone: String, priority: String) {
        let alertId = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        let dict: [String: Any] = [
            "deviceId": deviceId,
            "message": "Device \(deviceId.prefix(6)) just left \(leftZone == "workplace" ? "the workplace" : "home")!",
            "timestamp": timestamp,
            "priority": priority,
            "type": "departure"
        ]
        dbRef.child("alerts").child(alertId).setValue(dict)
    }

    private func createArrivalAlert(for deviceId: String, arrivedAt zone: String, priority: String) {
        let alertId = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        let dict: [String: Any] = [
            "deviceId": deviceId,
            "message": "Device \(deviceId.prefix(6)) \(priority == "high" ? "just arrived at" : "arrived at") \(zone == "Workplace" ? "workplace" : "home").",
            "timestamp": timestamp,
            "priority": priority,
            "type": "arrival"
        ]
        dbRef.child("alerts").child(alertId).setValue(dict)
    }

    // MARK: - Local Notifications

    private func sendLocalNotification(title: String, body: String, isHighPriority: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if isHighPriority {
            content.interruptionLevel = .timeSensitive
        } else {
            content.interruptionLevel = .active
        }

        // Fire immediately (1 second delay for reliability)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[AlertService] ❌ Notification error: \(error)")
            } else {
                print("[AlertService] ✅ Notification sent: \(title)")
            }
        }
    }

    // MARK: - Alert Stream

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
                        let priority = alertDict["priority"] as? String ?? "normal"
                        let type = alertDict["type"] as? String ?? "departure"
                        alerts.append(Alert(
                            id: id,
                            deviceId: devId,
                            message: msg,
                            timestamp: Date(timeIntervalSince1970: ts),
                            priority: priority,
                            type: type
                        ))
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
