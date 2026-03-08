Project: Calculator Admin iOS App

Framework: SwiftUI
Architecture: MVVM + Services
Navigation: TabView

Tabs:

1. Map
2. Devices
3. Alerts
4. Settings

Authentication:

- Sign in with Apple
- Sign in with Google

Core Features:

- Map with device markers
- Device list
- Device focus tracking
- Geofence configuration
- Alert feed
- Admin settings

Models:

Device

- id: String
- name: String
- latitude: Double
- longitude: Double
- status: String

Alert

- id: String
- deviceId: String
- message: String
- timestamp: Date

Geofence

- id: String
- deviceId: String
- latitude: Double
- longitude: Double
- radius: Double
