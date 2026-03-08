import SwiftUI

struct DeviceDetailView: View {
    let deviceId: String
    @StateObject private var viewModel = DeviceDetailViewModel()

    var body: some View {
        Form {
            if let device = viewModel.device {
                Section(header: Text("Device Info")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(device.name)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(device.status)
                            .foregroundColor(device.status == "Active" ? .green : .red)
                    }
                }

                Section(header: Text("Geofence")) {
                    HStack {
                        Text("Radius (m)")
                        Spacer()
                        TextField("Radius", value: $viewModel.geofenceRadius, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Button("Update Geofence") {
                        Task {
                            await viewModel.updateGeofence()
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Device Details")
        .task {
            await viewModel.loadDevice(id: deviceId)
        }
    }
}
