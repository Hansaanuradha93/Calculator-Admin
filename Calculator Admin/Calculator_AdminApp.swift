//
//  Calculator_AdminApp.swift
//  Calculator Admin
//
//  Created by Hansa Wickramanayake on 2026-03-08.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import GoogleMaps

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

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
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
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }

            DeviceListView()
                .tabItem {
                    Label("Devices", systemImage: "iphone")
                }

            AlertsView()
                .tabItem {
                    Label("Alerts", systemImage: "bell")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
