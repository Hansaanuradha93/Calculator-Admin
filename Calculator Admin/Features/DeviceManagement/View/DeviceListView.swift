import SwiftUI

struct DeviceListView: View {
    @StateObject private var viewModel = DeviceListViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.devices) { device in
                NavigationLink(destination: DeviceDetailView(deviceId: device.id)) {
                    VStack(alignment: .leading) {
                        Text(device.name)
                            .font(.headline)
                        Text(device.status)
                            .font(.subheadline)
                            .foregroundColor(device.status == "Active" ? .green : .red)
                    }
                }
            }
            .navigationTitle("Devices")
            .task {
                await viewModel.loadDevices()
            }
        }
    }
}
