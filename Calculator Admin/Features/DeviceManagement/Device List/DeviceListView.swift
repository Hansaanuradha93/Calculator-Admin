import SwiftUI

struct DeviceListView: View {
    @StateObject private var viewModel = DeviceListViewModel()
    @State private var searchText = ""
    @State private var selectedTab = "All"
    
    let tabs = ["All", "Connected", "Idle", "Offline"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search by device name or ID...", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(14)
                    .background(Color(red: 0.16, green: 0.16, blue: 0.18))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    // Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ForEach(tabs, id: \.self) { tab in
                                VStack(spacing: 8) {
                                    Text(tab)
                                        .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium))
                                        .foregroundColor(selectedTab == tab ? .orange : .gray)
                                    
                                    Rectangle()
                                        .fill(selectedTab == tab ? Color.orange : Color.clear)
                                        .frame(height: 2)
                                }
                                .onTapGesture {
                                    withAnimation(.easeInOut) {
                                        selectedTab = tab
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.bottom, 16)
                    
                    // Device List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredDevices) { device in
                                NavigationLink(destination: DeviceDetailView(deviceId: device.id)) {
                                    DeviceRowView(device: device)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Devices")
            .onAppear {
                Task {
                    await viewModel.loadDevices()
                }
            }
        }
    }
    
    var filteredDevices: [Device] {
        var filtered = viewModel.devices
        if searchText.isEmpty == false {
            filtered = filtered.filter { $0.name.lowercased().contains(searchText.lowercased()) || $0.id.lowercased().contains(searchText.lowercased()) }
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
}

struct DeviceRowView: View {
    let device: Device
    
    var statusColor: Color {
        switch device.status {
        case "Active": return .green
        case "Idle": return .yellow
        case "Inactive": return .gray
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Placeholder for device image
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 56, height: 56)
                Image(systemName: "tv.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("ID: \(device.id)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(device.status == "Active" ? "Online" : device.status == "Inactive" ? "Offline" : device.status)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(statusColor)
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(red: 0.11, green: 0.11, blue: 0.12)) // Dark rounded background
        .clipShape(RoundedRectangle(cornerRadius: 36))
        .overlay(
            RoundedRectangle(cornerRadius: 36)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
