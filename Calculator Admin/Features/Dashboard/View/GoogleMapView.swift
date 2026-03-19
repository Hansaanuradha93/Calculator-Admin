import SwiftUI
import GoogleMaps

struct GoogleMapView: UIViewRepresentable {
    var devices: [Device]
    @Binding var selectedDevice: Device?

    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        // Provide a default camera or configure based on devices
        let camera = GMSCameraPosition.camera(withLatitude: 37.7749, longitude: -122.4194, zoom: 10.0)
        options.camera = camera
        options.frame = .zero
        
        let mapView = GMSMapView(options: options)
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        uiView.clear()
        
        var bounds = GMSCoordinateBounds()
        var hasValidCoordinates = false

        for device in devices {
            var coordinate: CLLocationCoordinate2D?
            var iconName = "iphone.circle.fill"
            var color = UIColor.systemBlue
            
            if device.currentSafeZone == "home", let home = device.home {
                coordinate = home.coordinate
                iconName = "house.fill"
                color = UIColor.systemGreen
            } else if device.currentSafeZone == "workplace", let work = device.workplace {
                coordinate = work.coordinate
                iconName = "briefcase.fill"
                color = UIColor.systemOrange
            } else if device.currentSafeZone == "none" {
                coordinate = device.coordinate
                iconName = "smallcircle.filled.circle.fill"
                color = UIColor.systemRed
            } else {
                coordinate = device.coordinate
            }

            if let coord = coordinate {
                bounds = bounds.includingCoordinate(coord)
                hasValidCoordinates = true
                
                let marker = GMSMarker(position: coord)
                marker.title = device.name
                
                // Create a custom UI Image from SF Symbols
                let configuration = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
                let image = UIImage(systemName: iconName, withConfiguration: configuration)?.withTintColor(color, renderingMode: .alwaysOriginal)
                
                let markerView = UIImageView(image: image)
                markerView.backgroundColor = .white
                markerView.layer.cornerRadius = 16
                markerView.clipsToBounds = true
                
                marker.iconView = markerView
                marker.userData = device
                marker.map = uiView
                
                // If it's the selected device, we might want to center or highlight it
                if selectedDevice?.id == device.id {
                    uiView.selectedMarker = marker
                }
            }
        }
        
        if hasValidCoordinates && devices.count > 0 && context.coordinator.isFirstLayout {
            let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
            uiView.animate(with: update)
            context.coordinator.isFirstLayout = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView
        var isFirstLayout = true

        init(_ parent: GoogleMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let device = marker.userData as? Device {
                parent.selectedDevice = device
            }
            return false
        }
        
        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            parent.selectedDevice = nil
        }
    }
}
