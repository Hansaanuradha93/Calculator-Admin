import SwiftUI
import MapKit

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedDevice: Device?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(selection: $selectedDevice) {
                    ForEach(viewModel.devices) { device in
                        Annotation(device.name, coordinate: device.coordinate) {
                            Image(systemName: "iphone.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.orange)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .tag(device)
                    }
                }
                .ignoresSafeArea(edges: .top)

                // Overlay for Selected Device
                if let device = selectedDevice ?? viewModel.devices.first {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Device ID: \(device.id)")
                            .font(.system(size: 18, weight: .bold, design: .default))
                            .foregroundColor(.primary)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(device.status == "Active" ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text("\(device.status) • Last seen: 2m ago")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                        }
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
            .task {
                await viewModel.loadDevices()
            }
        }
    }
}
