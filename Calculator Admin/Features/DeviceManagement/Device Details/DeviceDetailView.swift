import SwiftUI
import GoogleMaps

struct DeviceDetailView: View {
    let deviceId: String
    @StateObject private var viewModel = DeviceDetailViewModel()
    @EnvironmentObject var navigation: AppNavigation

    var body: some View {
        Group {
            if let device = viewModel.device {
                DeviceDetailContentView(device: device, viewModel: viewModel)
            } else {
                ProgressView("Loading device…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("Device Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadDevice(id: deviceId)
        }
        .alert("Safe Zone Saved", isPresented: $viewModel.showSaveConfirmation) { }
    }
}

// MARK: - Content

struct DeviceDetailContentView: View {
    let device: Device
    @ObservedObject var viewModel: DeviceDetailViewModel
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 20) {
                DeviceHeaderCard(device: device)
                DeviceStatsCard(device: device)
                SafeZoneCard(device: device, viewModel: viewModel)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Header Card

struct DeviceHeaderCard: View {
    let device: Device
    @EnvironmentObject var navigation: AppNavigation

    private var statusColor: Color {
        switch device.status {
        case let s where s.contains("Safe"): return .green
        case "Live Track": return .orange
        default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Device avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(device.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("ID: \(device.id)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(device.status)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(statusColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(statusColor.opacity(0.12))
                .clipShape(.capsule)
            }
            
            // Live Track Button — navigates to Map tab
            Button("Live Track", systemImage: "location.fill", action: {
                navigation.navigateToMap(focusingDevice: device.id)
            })
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.orange.gradient)
            .clipShape(.rect(cornerRadius: 14))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }
}

// MARK: - Stats Card

struct DeviceStatsCard: View {
    let device: Device

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Device Info", systemImage: "info.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.orange)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatTile(icon: "clock.fill", label: "Last Seen", value: formattedTimestamp)
                StatTile(icon: "eye.fill", label: "Watching", value: device.isBeingWatched == true ? "Active" : "Off")
                StatTile(icon: "house.fill", label: "Home Zone", value: device.home != nil ? "Set" : "Not Set")
                StatTile(icon: "building.2.fill", label: "Work Zone", value: device.workplace != nil ? "Set" : "Not Set")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var formattedTimestamp: String {
        guard let ts = device.timestamp else { return "N/A" }
        let date = Date(timeIntervalSince1970: ts)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}

struct StatTile: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.orange)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.primary.opacity(0.04))
        .clipShape(.rect(cornerRadius: 14))
    }
}

// MARK: - Safe Zone Card

struct SafeZoneCard: View {
    let device: Device
    @ObservedObject var viewModel: DeviceDetailViewModel
    @State private var isMapExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Label("Set Safe Zone", systemImage: "location.viewfinder")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.orange)

            // Address Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search address or place…", text: $viewModel.addressQuery)
                    .font(.system(size: 15))
                    .submitLabel(.search)
                    .onSubmit {
                        viewModel.searchAddress()
                    }
                
                if viewModel.isGeocodingLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.06))
            .clipShape(.rect(cornerRadius: 12))
            
            // Resolved address display
            if !viewModel.resolvedAddress.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.orange)
                        .font(.system(size: 14))
                    Text(viewModel.resolvedAddress)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            // Interactive Google Map with expand toggle
            VStack(spacing: 0) {
                if let coord = viewModel.selectedCoordinate {
                    SafeZoneMapView(
                        selectedCoordinate: Binding(
                            get: { viewModel.selectedCoordinate ?? device.coordinate },
                            set: { viewModel.onMapCoordinateChanged($0) }
                        ),
                        radius: viewModel.geofenceRadius,
                        initialCenter: coord
                    )
                    .frame(height: isMapExpanded ? 400 : 220)
                    .clipShape(.rect(cornerRadius: 16))
                    .animation(.easeInOut(duration: 0.3), value: isMapExpanded)
                }
                
                // Expand / Collapse button
                Button {
                    isMapExpanded.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isMapExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        Text(isMapExpanded ? "Collapse Map" : "Expand Map")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
            
            // Hint text
            Text("Tap on the map or drag the pin to set the center. Search an address above for precision.")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)

            // Radius Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Radius", systemImage: "arrow.left.and.right.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.formattedRadius)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.orange)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: viewModel.geofenceRadius)
                }
                
                Slider(value: $viewModel.geofenceRadius, in: 50...2000, step: 25) {
                    Text("Radius")
                } minimumValueLabel: {
                    Text("50m")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("2km")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .tint(.orange)
            }
            .padding(14)
            .background(Color.primary.opacity(0.04))
            .clipShape(.rect(cornerRadius: 14))

            // Action Buttons
            HStack(spacing: 12) {
                Button("Set Home", systemImage: "house.fill", action: {
                    viewModel.updateSafeZone(zoneType: "home")
                })
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.green.gradient)
                .clipShape(.rect(cornerRadius: 14))

                Button("Set Workplace", systemImage: "building.2.fill", action: {
                    viewModel.updateSafeZone(zoneType: "workplace")
                })
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.orange.gradient)
                .clipShape(.rect(cornerRadius: 14))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }
}
