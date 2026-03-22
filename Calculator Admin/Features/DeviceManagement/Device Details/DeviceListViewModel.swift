import Foundation
import Combine

@MainActor
class DeviceListViewModel: ObservableObject {
    @Published var devices: [Device] = []
    private var streamTask: Task<Void, Never>?

    private let deviceService: DeviceServiceProtocol

    init(deviceService: DeviceServiceProtocol = DeviceService()) {
        self.deviceService = deviceService
    }

    func loadDevices() {
        streamTask?.cancel()
        streamTask = Task {
            for await updatedDevices in deviceService.devicesStream() {
                self.devices = updatedDevices
            }
        }
    }
    
    deinit {
        streamTask?.cancel()
    }
}
