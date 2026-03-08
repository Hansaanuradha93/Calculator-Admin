import SwiftUI
import MapKit

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            Map {
                ForEach(viewModel.devices) { device in
                    Annotation(device.name, coordinate: device.coordinate) {
                        Image(systemName: "iphone")
                            .padding(5)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle("Device Map")
            .task {
                await viewModel.loadDevices()
            }
        }
    }
}
