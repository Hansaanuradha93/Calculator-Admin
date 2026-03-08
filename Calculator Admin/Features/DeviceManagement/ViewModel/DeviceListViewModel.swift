import Foundation
import Combine

@MainActor
class DeviceListViewModel: ObservableObject {
    @Published var devices: [Device] = []

    private let deviceService: DeviceServiceProtocol

    init(deviceService: DeviceServiceProtocol = DeviceService()) {
        self.deviceService = deviceService
    }

    func loadDevices() async {
        do {
            devices = try await deviceService.fetchDevices()
        } catch {
            print("Error loading devices: \(error)")
        }
    }
}
