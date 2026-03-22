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
        .alert("\(viewModel.savedZoneType ?? "Safe Zone") Zone Saved", isPresented: $viewModel.showSaveConfirmation) { }
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
                SafeZoneCard(device: device, viewModel: viewModel, homeZone: viewModel.homeZone, workZone: viewModel.workZone)
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
    @ObservedObject var homeZone: ZoneEditorState
    @ObservedObject var workZone: ZoneEditorState
    @State private var isMapExpanded = false
    @FocusState private var isSearchFocused: Bool

    private var zone: ZoneEditorState { viewModel.selectedZoneType == .home ? homeZone : workZone }
    private var accentColor: Color { viewModel.selectedZoneType.accentColor }

    private var addressQueryBinding: Binding<String> {
        viewModel.selectedZoneType == .home ? $homeZone.addressQuery : $workZone.addressQuery
    }

    private var radiusBinding: Binding<Double> {
        viewModel.selectedZoneType == .home ? $homeZone.radius : $workZone.radius
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Label("Set Safe Zone", systemImage: "location.viewfinder")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.orange)

            // Home / Workplace Segmented Picker
            Picker("Zone Type", selection: $viewModel.selectedZoneType) {
                ForEach(ZoneType.allCases) { type in
                    Label(type.label, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.selectedZoneType) {
                // Clear search suggestions when switching tabs
                viewModel.placesService.clearSuggestions()
                isSearchFocused = false
            }

            // Status indicator for current zone
            HStack(spacing: 8) {
                Image(systemName: zone.isConfigured ? "checkmark.circle.fill" : "circle.dashed")
                    .foregroundStyle(zone.isConfigured ? accentColor : .secondary)
                Text(zone.isConfigured ? "\(viewModel.selectedZoneType.label) zone is configured" : "\(viewModel.selectedZoneType.label) zone not set")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(zone.isConfigured ? .primary : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(zone.isConfigured ? accentColor.opacity(0.08) : Color.primary.opacity(0.04))
            .clipShape(.rect(cornerRadius: 10))

            // Address Search Bar + Suggestions
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search address or place…", text: addressQueryBinding)
                        .font(.system(size: 15))
                        .focused($isSearchFocused)
                        .autocorrectionDisabled()

                    if viewModel.placesService.isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if !zone.addressQuery.isEmpty {
                        Button {
                            zone.addressQuery = ""
                            viewModel.placesService.clearSuggestions()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.primary.opacity(0.06))
                .clipShape(.rect(cornerRadius: 12))

                // Suggestions dropdown
                if !viewModel.placesService.suggestions.isEmpty && isSearchFocused {
                    VStack(spacing: 0) {
                        ForEach(viewModel.placesService.suggestions) { suggestion in
                            Button {
                                viewModel.selectSuggestion(suggestion)
                                isSearchFocused = false
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(accentColor)
                                        .font(.system(size: 18))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion.title)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)

                                        if !suggestion.subtitle.isEmpty {
                                            Text(suggestion.subtitle)
                                                .font(.system(size: 12))
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }

                            if suggestion.id != viewModel.placesService.suggestions.last?.id {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                    .background(Color.primary.opacity(0.04))
                    .clipShape(.rect(cornerRadius: 12))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.placesService.suggestions.count)

            // Resolved address display
            if !zone.resolvedAddress.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(accentColor)
                        .font(.system(size: 14))
                    Text(zone.resolvedAddress)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            // Interactive Google Map
            VStack(spacing: 0) {
                if let coord = zone.coordinate {
                    SafeZoneMapView(
                        selectedCoordinate: Binding(
                            get: { zone.coordinate ?? device.coordinate },
                            set: { viewModel.onMapCoordinateChanged($0) }
                        ),
                        radius: zone.radius,
                        initialCenter: coord
                    )
                    .frame(height: isMapExpanded ? 500 : 320)
                    .clipShape(.rect(cornerRadius: 16))
                    .animation(.easeInOut(duration: 0.3), value: isMapExpanded)
                    .id(viewModel.selectedZoneType) // Force map recreation on tab switch
                }

                Button {
                    isMapExpanded.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isMapExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        Text(isMapExpanded ? "Collapse Map" : "Expand Map")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }

            // Hint text
            Text("Tap the map or drag the pin to set the \(viewModel.selectedZoneType.label.lowercased()) center.")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)

            // Radius Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Radius", systemImage: "arrow.left.and.right.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(zone.formattedRadius)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: zone.radius)
                }

                Slider(value: radiusBinding, in: 50...2000, step: 25) {
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
                .tint(accentColor)
            }
            .padding(14)
            .background(Color.primary.opacity(0.04))
            .clipShape(.rect(cornerRadius: 14))

            // Save Button — contextual to active zone
            Button {
                viewModel.saveActiveZone()
            } label: {
                Label("Save \(viewModel.selectedZoneType.label)", systemImage: viewModel.selectedZoneType.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(accentColor.gradient)
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
