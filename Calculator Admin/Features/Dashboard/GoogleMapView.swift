import SwiftUI
import GoogleMaps
import CoreLocation

struct GoogleMapView: UIViewRepresentable {
    var devices: [Device]
    @Binding var selectedDevice: Device?
    var focusedDeviceId: String?

    func makeUIView(context: Context) -> GMSMapView {
        // Start location manager for fallback
        context.coordinator.locationManager.delegate = context.coordinator
        context.coordinator.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        context.coordinator.locationManager.requestWhenInUseAuthorization()

        let options = GMSMapViewOptions()
        let camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 2.0)
        options.camera = camera
        options.frame = .zero

        let mapView = GMSMapView(options: options)
        mapView.delegate = context.coordinator
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = false
        mapView.isMyLocationEnabled = true
        mapView.padding = UIEdgeInsets(top: 80, left: 0, bottom: 100, right: 0)

        context.coordinator.mapView = mapView
        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        uiView.clear()

        var bounds = GMSCoordinateBounds()
        var hasValidCoordinates = false
        var focusedCoordinate: CLLocationCoordinate2D?

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
                iconName = "exclamationmark.triangle.fill"
                color = UIColor.systemRed
            } else {
                coordinate = device.coordinate
            }

            if let coord = coordinate {
                bounds = bounds.includingCoordinate(coord)
                hasValidCoordinates = true

                let marker = GMSMarker(position: coord)
                marker.title = device.name
                marker.snippet = device.status

                let isSelected = selectedDevice?.id == device.id
                let markerView = buildMarkerView(
                    iconName: iconName,
                    color: color,
                    isSelected: isSelected
                )
                marker.iconView = markerView
                marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
                marker.userData = device
                marker.map = uiView

                if isSelected {
                    uiView.selectedMarker = marker
                }

                if device.id == focusedDeviceId {
                    focusedCoordinate = coord
                }
            }
        }

        // Camera positioning priority:
        // 1. Focused device (from "Live Track" navigation)
        // 2. Fit all device markers
        // 3. User's current location (fallback when no devices)
        if let focused = focusedCoordinate {
            let camera = GMSCameraPosition.camera(
                withLatitude: focused.latitude,
                longitude: focused.longitude,
                zoom: 16.0
            )
            uiView.animate(to: camera)
            context.coordinator.isFirstLayout = false
        } else if hasValidCoordinates && context.coordinator.isFirstLayout {
            let update = GMSCameraUpdate.fit(bounds, withPadding: 80)
            uiView.animate(with: update)
            context.coordinator.isFirstLayout = false
        } else if !hasValidCoordinates && context.coordinator.isFirstLayout {
            // No devices — request user location and focus on it
            context.coordinator.shouldFocusOnUserLocation = true
            context.coordinator.locationManager.requestLocation()
        }
    }

    // MARK: - Marker View Builder

    private func buildMarkerView(iconName: String, color: UIColor, isSelected: Bool) -> UIView {
        let size: CGFloat = isSelected ? 48 : 40
        let iconSize: CGFloat = isSelected ? 24 : 20

        let container = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        container.backgroundColor = color.withAlphaComponent(0.15)
        container.layer.cornerRadius = size / 2
        container.layer.borderWidth = isSelected ? 3 : 2
        container.layer.borderColor = color.cgColor

        if isSelected {
            container.layer.shadowColor = color.cgColor
            container.layer.shadowRadius = 8
            container.layer.shadowOpacity = 0.4
            container.layer.shadowOffset = .zero
        }

        let config = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .semibold)
        let imageView = UIImageView(
            image: UIImage(systemName: iconName, withConfiguration: config)?
                .withTintColor(color, renderingMode: .alwaysOriginal)
        )
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(
            x: (size - iconSize) / 2,
            y: (size - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )
        container.addSubview(imageView)

        return container
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, GMSMapViewDelegate, CLLocationManagerDelegate {
        var parent: GoogleMapView
        var isFirstLayout = true
        var shouldFocusOnUserLocation = false
        let locationManager = CLLocationManager()
        weak var mapView: GMSMapView?

        init(_ parent: GoogleMapView) {
            self.parent = parent
        }

        // MARK: - Map Delegate

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let device = marker.userData as? Device {
                parent.selectedDevice = device
            }
            return true
        }

        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            parent.selectedDevice = nil
        }

        // MARK: - Location Delegate

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard shouldFocusOnUserLocation,
                  let location = locations.last,
                  let mapView else { return }

            let camera = GMSCameraPosition.camera(
                withLatitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                zoom: 14.0
            )
            mapView.animate(to: camera)
            shouldFocusOnUserLocation = false
            isFirstLayout = false
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("[GoogleMapView] Location error: \(error.localizedDescription)")
        }

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                if shouldFocusOnUserLocation {
                    manager.requestLocation()
                }
            default:
                break
            }
        }
    }
}
