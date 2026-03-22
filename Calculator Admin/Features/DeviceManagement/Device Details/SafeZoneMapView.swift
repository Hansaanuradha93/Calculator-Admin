import SwiftUI
import GoogleMaps
import CoreLocation

/// A Google Maps view for selecting a Safe Zone center point.
/// Supports: drag the marker, tap to place, and external coordinate updates from search.
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

        // Track the current coordinate that the map knows about
        context.coordinator.currentMapCoordinate = initialCenter

        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        let coord = context.coordinator

        // Always sync the circle radius (for slider changes)
        coord.circle?.radius = radius

        // Check if this is a genuine EXTERNAL coordinate change
        // (e.g. search result selected) vs. a re-render from our own binding update
        let incoming = selectedCoordinate
        let current = coord.currentMapCoordinate

        let isExternalChange = current == nil ||
            abs(incoming.latitude - current!.latitude) > 0.0001 ||
            abs(incoming.longitude - current!.longitude) > 0.0001

        // Only move the marker/camera for external changes, never during user interaction
        if isExternalChange && !coord.isUserInteracting {
            coord.marker?.position = incoming
            coord.circle?.position = incoming
            coord.currentMapCoordinate = incoming

            let camera = GMSCameraPosition.camera(
                withLatitude: incoming.latitude,
                longitude: incoming.longitude,
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
        /// The coordinate the map currently shows — updated by both user and external changes
        var currentMapCoordinate: CLLocationCoordinate2D?
        /// True while the user is actively dragging
        var isUserInteracting = false

        init(_ parent: SafeZoneMapView) {
            self.parent = parent
        }

        // MARK: - Drag Events

        func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
            isUserInteracting = true
        }

        func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
            circle?.position = marker.position
        }

        func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
            let newCoord = marker.position
            circle?.position = newCoord
            currentMapCoordinate = newCoord
            isUserInteracting = false
            parent.selectedCoordinate = newCoord
        }

        // MARK: - Tap to Place
        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            marker?.position = coordinate
            circle?.position = coordinate
            currentMapCoordinate = coordinate
            parent.selectedCoordinate = coordinate
        }
    }
}
