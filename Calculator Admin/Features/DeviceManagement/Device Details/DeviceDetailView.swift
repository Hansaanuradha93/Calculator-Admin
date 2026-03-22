import SwiftUI
import MapKit

struct DeviceDetailView: View {
    let deviceId: String
    @StateObject private var viewModel = DeviceDetailViewModel()

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
                DeviceLocationCard(device: device)
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

    private var statusColor: Color {
        switch device.status {
        case let s where s.contains("Safe"): return .green
        case "Live Track": return .orange
        default: return .gray
        }
    }

    var body: some View {
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
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }
}

// MARK: - Location Card (Mini-Map)

struct DeviceLocationCard: View {
    let device: Device

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Current Location", systemImage: "location.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.orange)

            Map(initialPosition: .region(
                MKCoordinateRegion(
                    center: device.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )) {
                Annotation(device.name, coordinate: device.coordinate) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.25))
                            .frame(width: 44, height: 44)
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 16, height: 16)
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .frame(height: 200)
            .clipShape(.rect(cornerRadius: 16))
            .allowsHitTesting(false)

            // Coordinate Labels
            HStack(spacing: 16) {
                CoordinateLabel(title: "LAT", value: String(format: "%.5f", device.latitude ?? 0))
                CoordinateLabel(title: "LNG", value: String(format: "%.5f", device.longitude ?? 0))
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

struct CoordinateLabel: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.12))
                .clipShape(.rect(cornerRadius: 4))

            Text(value)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
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
                StatTile(
                    icon: "clock.fill",
                    label: "Last Seen",
                    value: formattedTimestamp
                )
                StatTile(
                    icon: "eye.fill",
                    label: "Watching",
                    value: device.isBeingWatched == true ? "Active" : "Off"
                )
                StatTile(
                    icon: "house.fill",
                    label: "Home Zone",
                    value: device.home != nil ? "Set" : "Not Set"
                )
                StatTile(
                    icon: "building.2.fill",
                    label: "Work Zone",
                    value: device.workplace != nil ? "Set" : "Not Set"
                )
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Set Safe Zone", systemImage: "location.viewfinder")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.orange)

            // Interactive map
            ZStack {
                Map(initialPosition: .region(
                    MKCoordinateRegion(
                        center: viewModel.selectedCoordinate ?? device.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                ))
                .frame(height: 220)
                .clipShape(.rect(cornerRadius: 16))

                // Center pin
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.red)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .offset(y: -18)
            }

            // Radius input
            HStack(spacing: 12) {
                Image(systemName: "arrow.left.and.right.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.orange)

                Text("Radius")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                TextField("150", value: $viewModel.geofenceRadius, format: .number)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 10))

                Text("m")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button("Set Home", systemImage: "house.fill", action: { viewModel.updateSafeZone(zoneType: "home") })
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.green.gradient)
                    .clipShape(.rect(cornerRadius: 14))

                Button("Set Workplace", systemImage: "building.2.fill", action: { viewModel.updateSafeZone(zoneType: "workplace") })
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
