import Foundation
import Combine

@MainActor
class DeviceListViewModel: ObservableObject {
    @Published var devices: [Device] = []
    @Published var searchText = ""
    @Published var selectedTab = "All"
    
    let tabs = ["All", "Connected", "Idle", "Offline"]
    
    private var streamTask: Task<Void, Never>?
    private let deviceService: DeviceServiceProtocol

    init(deviceService: DeviceServiceProtocol = DeviceService()) {
        self.deviceService = deviceService
    }

    var filteredDevices: [Device] {
        var filtered = devices
        
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            filtered = filtered.filter {
                $0.name.lowercased().contains(query) ||
                $0.id.lowercased().contains(query)
            }
        }
        
        switch selectedTab {
            case "Connected":
                return filtered.filter { $0.status == "Active" }
            case "Idle":
                return filtered.filter { $0.status == "Idle" }
            case "Offline":
                return filtered.filter { $0.status == "Inactive" }
            default:
                return filtered
        }
    }
    
    func selectTab(_ tab: String) {
        selectedTab = tab
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
