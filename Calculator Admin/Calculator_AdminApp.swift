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

    func navigateToMap(focusingDevice deviceId: String) {
        focusedDeviceId = deviceId
        selectedTab = .map
    }
}

enum AppTab: Hashable {
    case map, devices, alerts, settings
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Read Google Maps API Key from Info.plist
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String {
            GMSServices.provideAPIKey(apiKey)
        } else {
            print("Error: GoogleMapsAPIKey not found in Info.plist")
        }

        return true
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
            AlertService.shared.startMonitoring()
        }
    }
}

