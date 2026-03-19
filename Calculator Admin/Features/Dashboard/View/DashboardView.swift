import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedDevice: Device?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Use the Google Maps wrapper
                GoogleMapView(devices: viewModel.devices, selectedDevice: $selectedDevice)
                    .ignoresSafeArea(edges: .top)

                // Overlay for Selected Device
                if let device = selectedDevice {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Device ID: \(device.id)")
                            .font(.system(size: 18, weight: .bold, design: .default))
                            .foregroundColor(.primary)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(device.status.contains("Safe") ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text("\(device.status)")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        Toggle(isOn: Binding(
                            get: { device.isBeingWatched ?? false },
                            set: { newValue in
                                viewModel.setWatchStatus(for: device.id, isWatching: newValue)
                            }
                        )) {
                            Text("Live Track User")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .tint(.red)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding()
                }
            }
            .navigationTitle("Device Map")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadDevices()
            }
            .onChange(of: viewModel.devices) { newDevices in
                if let selected = selectedDevice,
                   let updated = newDevices.first(where: { $0.id == selected.id }) {
                    selectedDevice = updated
                }
            }
        }
    }
}
