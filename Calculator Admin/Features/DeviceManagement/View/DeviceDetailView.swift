import SwiftUI

struct DeviceDetailView: View {
    let deviceId: String
    @StateObject private var viewModel = DeviceDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let device = viewModel.device {
                    // Header Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "iphone.gen3")
                                    .font(.system(size: 24))
                                    .foregroundColor(.primary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(device.name)
                                    .font(.system(size: 20, weight: .bold))
                                Text("ID: \(device.id)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(device.status == "Active" ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text(device.status)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(device.status == "Active" ? .green : .red)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background((device.status == "Active" ? Color.green : Color.red).opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                    // Geofence Configuration Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "location.viewfinder")
                                .font(.system(size: 20))
                                .foregroundColor(.orange)
                            Text("Geofence Radius (m)")
                                .font(.system(size: 16, weight: .semibold))
                        }

                        TextField("Radius", value: $viewModel.geofenceRadius, format: .number)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)

                        Button {
                            Task {
                                await viewModel.updateGeofence()
                            }
                        } label: {
                            Text("Update Geofence")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.orange)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                } else {
                    ProgressView()
                        .padding(.top, 40)
                }
            }
            .padding()
        }
        .background(Color("BackgroundLight").ignoresSafeArea()) // Uses #f8f7f5
        .navigationTitle("Device Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDevice(id: deviceId)
        }
    }
}
