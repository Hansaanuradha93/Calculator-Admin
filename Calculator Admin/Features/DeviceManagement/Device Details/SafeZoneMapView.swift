import SwiftUI
import GoogleMaps
import CoreLocation

/// A Google Maps view for selecting a Safe Zone center point.
/// Displays a draggable marker and a circle overlay representing the radius.
struct SafeZoneMapView: UIViewRepresentable {
    @Binding var selectedCoordinate: CLLocationCoordinate2D
    var radius: Double
    var initialCenter: CLLocationCoordinate2D

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(
            withLatitude: initialCenter.latitude,
            longitude: initialCenter.longitude,
            zoom: 15.0
        )
        let options = GMSMapViewOptions()
        options.camera = camera
        options.frame = .zero

        let mapView = GMSMapView(options: options)
        mapView.delegate = context.coordinator
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = false
        mapView.settings.tiltGestures = false

        // Add initial marker
        let marker = GMSMarker(position: initialCenter)
        marker.isDraggable = true
        marker.title = "Safe Zone Center"
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        marker.icon = UIImage(systemName: "mappin.circle.fill", withConfiguration: config)?
            .withTintColor(.systemOrange, renderingMode: .alwaysOriginal)
        marker.map = mapView
        context.coordinator.marker = marker

        // Add radius circle
        let circle = GMSCircle(position: initialCenter, radius: radius)
        circle.fillColor = UIColor.systemOrange.withAlphaComponent(0.15)
        circle.strokeColor = UIColor.systemOrange.withAlphaComponent(0.6)
        circle.strokeWidth = 2
        circle.map = mapView
        context.coordinator.circle = circle

        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // Update circle radius when it changes
        context.coordinator.circle?.radius = radius
        context.coordinator.circle?.position = selectedCoordinate
        context.coordinator.marker?.position = selectedCoordinate
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: SafeZoneMapView
        var marker: GMSMarker?
        var circle: GMSCircle?

        init(_ parent: SafeZoneMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
            parent.selectedCoordinate = marker.position
            circle?.position = marker.position
        }

        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            // Move marker to tapped location
            marker?.position = coordinate
            parent.selectedCoordinate = coordinate
            circle?.position = coordinate
        }
    }
}
