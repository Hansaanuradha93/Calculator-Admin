import SwiftUI
import GoogleMaps
import CoreLocation

/// A Google Maps view for selecting a Safe Zone center point.
/// Supports: drag the marker, tap to place, and external coordinate updates.
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

        // Draggable marker
        let marker = GMSMarker(position: initialCenter)
        marker.isDraggable = true
        marker.title = "Safe Zone Center"
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        marker.icon = UIImage(systemName: "mappin.circle.fill", withConfiguration: config)?
            .withTintColor(.systemOrange, renderingMode: .alwaysOriginal)
        marker.map = mapView
        context.coordinator.marker = marker

        // Radius circle overlay
        let circle = GMSCircle(position: initialCenter, radius: radius)
        circle.fillColor = UIColor.systemOrange.withAlphaComponent(0.15)
        circle.strokeColor = UIColor.systemOrange.withAlphaComponent(0.6)
        circle.strokeWidth = 2
        circle.map = mapView
        context.coordinator.circle = circle

        // Store initial coordinate for change detection
        context.coordinator.lastExternalCoordinate = initialCenter

        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        let coord = context.coordinator

        // Always update the circle radius (slider changes)
        coord.circle?.radius = radius

        // Only move marker + camera if the coordinate was changed externally
        // (e.g., a place suggestion was selected), NOT from a drag
        let current = selectedCoordinate
        let last = coord.lastExternalCoordinate

        let coordinateChanged = last == nil ||
            abs(current.latitude - last!.latitude) > 0.00001 ||
            abs(current.longitude - last!.longitude) > 0.00001

        if coordinateChanged && !coord.isDragging {
            coord.marker?.position = current
            coord.circle?.position = current
            coord.lastExternalCoordinate = current

            let camera = GMSCameraPosition.camera(
                withLatitude: current.latitude,
                longitude: current.longitude,
                zoom: uiView.camera.zoom
            )
            uiView.animate(to: camera)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: SafeZoneMapView
        var marker: GMSMarker?
        var circle: GMSCircle?
        var lastExternalCoordinate: CLLocationCoordinate2D?
        var isDragging = false

        init(_ parent: SafeZoneMapView) {
            self.parent = parent
        }

        // MARK: - Drag Events

        func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
            isDragging = true
        }

        func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
            // Update circle position live while dragging
            circle?.position = marker.position
        }

        func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
            isDragging = false
            let newCoord = marker.position
            circle?.position = newCoord
            lastExternalCoordinate = newCoord
            parent.selectedCoordinate = newCoord
        }

        // MARK: - Tap to Place

        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            marker?.position = coordinate
            circle?.position = coordinate
            lastExternalCoordinate = coordinate
            parent.selectedCoordinate = coordinate
        }
    }
}
