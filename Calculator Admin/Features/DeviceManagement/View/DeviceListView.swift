import SwiftUI

struct DeviceListView: View {
    @StateObject private var viewModel = DeviceListViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.devices) { device in
                        NavigationLink(destination: DeviceDetailView(deviceId: device.id)) {
                            HStack(spacing: 16) {
                                // Device Icon
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.secondarySystemBackground))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "iphone.gen3")
                                        .font(.system(size: 24))
                                        .foregroundColor(.primary)
                                }

                                // Details
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(device.name)
                                        .font(.system(size: 16, weight: .semibold, design: .default))
                                        .foregroundColor(.primary)

                                    Text("ID: \(device.id)")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()

                                // Status Dot
                                Circle()
                                    .fill(device.status == "Active" ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                }
                .padding()
            }
            .background(Color("BackgroundLight").ignoresSafeArea()) // Uses #f8f7f5
            .navigationTitle("Devices")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadDevices()
            }
        }
    }
}
