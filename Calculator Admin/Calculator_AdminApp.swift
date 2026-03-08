//
//  Calculator_AdminApp.swift
//  Calculator Admin
//
//  Created by Hansa Wickramanayake on 2026-03-08.
//

import SwiftUI

@main
struct Calculator_AdminApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                AuthView(viewModel: authViewModel)
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
