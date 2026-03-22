import SwiftUI
import GoogleMaps

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var navigation: AppNavigation
    @State private var selectedDevice: Device?
    @State private var showDeviceList = false

    var body: some View {
        ZStack {
            // Full-screen Google Map
            GoogleMapView(
                devices: viewModel.devices,
                selectedDevice: $selectedDevice,
                focusedDeviceId: navigation.focusedDeviceId
            )
            .ignoresSafeArea()

            // Top overlay — search / status bar
            VStack {
                topBar
                Spacer()
            }

            // Bottom overlay — device card or device list
            VStack {
                Spacer()

                if let device = selectedDevice {
                    DeviceInfoCard(
                        device: device,
                        onToggleWatch: { newValue in
                            viewModel.setWatchStatus(for: device.id, isWatching: newValue)
                        },
                        onDismiss: { selectedDevice = nil },
                        onViewDetails: {
                            navigation.selectedTab = .devices
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                } else if showDeviceList {
                    DeviceQuickList(
                        devices: viewModel.devices,
                        onSelect: { device in
                            selectedDevice = device
                            showDeviceList = false
                        },
                        onDismiss: { showDeviceList = false }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedDevice?.id)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showDeviceList)
        }
        .onAppear {
            viewModel.loadDevices()
        }
        .onChange(of: viewModel.devices) { _, newDevices in
            if let selected = selectedDevice,
               let updated = newDevices.first(where: { $0.id == selected.id }) {
                selectedDevice = updated
            }
        }
        .onChange(of: navigation.focusedDeviceId) { _, deviceId in
            if let deviceId,
               let device = viewModel.devices.first(where: { $0.id == deviceId }) {
                selectedDevice = device
                navigation.focusedDeviceId = nil
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text("Device Map")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                Text("\(viewModel.devices.count) device\(viewModel.devices.count == 1 ? "" : "s") tracked")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Device list toggle
            Button {
                showDeviceList.toggle()
                if showDeviceList { selectedDevice = nil }
            } label: {
                Image(systemName: showDeviceList ? "xmark" : "list.bullet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            // Status indicators
            HStack(spacing: 6) {
                statusDot(color: .green, count: viewModel.safeDeviceCount)
                statusDot(color: .red, count: viewModel.liveTrackCount)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private func statusDot(color: Color, count: Int) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(.capsule)
    }
}

// MARK: - Device Info Card

struct DeviceInfoCard: View {
    let device: Device
    var onToggleWatch: (Bool) -> Void
    var onDismiss: () -> Void
    var onViewDetails: () -> Void

    private var statusColor: Color {
        switch device.currentSafeZone {
        case "home": return .green
        case "workplace": return .orange
        case "none": return .red
        default: return .gray
        }
    }

    private var statusLabel: String {
        switch device.currentSafeZone {
        case "home": return "Home Zone"
        case "workplace": return "Workplace"
        case "none": return "Outside Zones"
        default: return "Unknown"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.primary.opacity(0.2))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 8)

            VStack(spacing: 14) {
                // Header row
                HStack(spacing: 14) {
                    // Device avatar
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(statusColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.primary)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            Text(statusLabel)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Circle())
                    }
                }

                Divider()

                // Controls row
                HStack(spacing: 16) {
                    // Watch toggle
                    Toggle(isOn: Binding(
                        get: { device.isBeingWatched ?? false },
                        set: { onToggleWatch($0) }
                    )) {
                        HStack(spacing: 8) {
                            Image(systemName: device.isBeingWatched == true ? "eye.fill" : "eye.slash.fill")
                                .foregroundStyle(device.isBeingWatched == true ? .red : .secondary)
                            Text("Live Track")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    .tint(.red)

                    // Coordinate display
                    if let lat = device.latitude, let lng = device.longitude {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.4f°", lat))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.4f°", lng))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Last seen
                if let ts = device.timestamp {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text("Last seen \(formattedTime(ts))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
    }

    private func formattedTime(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}

// MARK: - Device Quick List

struct DeviceQuickList: View {
    let devices: [Device]
    var onSelect: (Device) -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("All Devices")
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Text("\(devices.count)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(.capsule)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 16)

            // Device list
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 2) {
                    ForEach(devices) { device in
                        Button {
                            onSelect(device)
                        } label: {
                            deviceRow(device)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 280)
        }
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
    }

    private func deviceRow(_ device: Device) -> some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(device.currentSafeZone == "none" ? Color.red : Color.green)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(device.status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if device.isBeingWatched == true {
                Image(systemName: "eye.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.red)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
