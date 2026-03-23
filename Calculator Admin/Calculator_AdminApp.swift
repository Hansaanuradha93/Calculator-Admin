import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import GoogleMaps
import Combine

// MARK: - App-Wide Navigation State
class AppNavigation: ObservableObject {
    @Published var selectedTab: AppTab = .map
    @Published var focusedDeviceId: String?
    @Published var hasActiveHomeArrival: Bool = false

    private var homeArrivalObserver: Any?
    private var dismissTimer: DispatchWorkItem?

    init() {
        // Listen for home arrival events from AlertService
        homeArrivalObserver = NotificationCenter.default.addObserver(
            forName: .deviceArrivedHome,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.triggerHomeArrivalPulse()
        }
    }

    deinit {
        if let observer = homeArrivalObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        dismissTimer?.cancel()
    }

    func navigateToMap(focusingDevice deviceId: String) {
        focusedDeviceId = deviceId
        selectedTab = .map
    }

    func triggerHomeArrivalPulse() {
        hasActiveHomeArrival = true

        // Auto-dismiss after 5 minutes (300 seconds)
        dismissTimer?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.hasActiveHomeArrival = false
        }
        dismissTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 300, execute: work)
    }

    func dismissHomeArrivalPulse() {
        dismissTimer?.cancel()
        hasActiveHomeArrival = false
    }
}

enum AppTab: Hashable {
    case map, devices, alerts, settings
}

import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Set the notification delegate to handle foreground notifications
        UNUserNotificationCenter.current().delegate = self

        // Read Google Maps API Key from Info.plist
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String {
            GMSServices.provideAPIKey(apiKey)
        } else {
            print("Error: GoogleMapsAPIKey not found in Info.plist")
        }

        return true
    }

    // This method allows notifications to be presented (as banners/sound) even while the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show everything: banner, sound, and update the badge
        completionHandler([.banner, .list, .sound, .badge])
    }

    // Handles user interaction (e.g., tapping the notification)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Example: could navigate to the Alerts tab on tap
        completionHandler()
    }
}

@main
struct Calculator_AdminApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appNavigation = AppNavigation()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(appNavigation)
            } else {
                AuthView(viewModel: authViewModel)
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var navigation: AppNavigation

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            Tab("Map", systemImage: "map", value: .map) {
                DashboardView()
            }

            Tab("Devices", systemImage: "iphone", value: .devices) {
                DeviceListView()
            }

            Tab("Alerts", systemImage: "bell", value: .alerts) {
                AlertsView()
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .onAppear {
            AlertService.shared.requestNotificationPermissions()
            AlertService.shared.startMonitoring()
        }
    }
}

