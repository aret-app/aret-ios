import SwiftUI
import UIKit
import MapLibre
import CoreLocation

/// A native OpenStreetMap map layer. The public OpenFreeMap style currently
/// provides a vector basemap, NOT downloadable topo packs or a certified
/// hiking map. MapKit remains the working fallback in Explore.
struct ARETTopoMapView: UIViewRepresentable {
    let routeID: String?
    let routeCoordinates: [ARETCoordinate]
    let recordedCoordinates: [CLLocationCoordinate2D]
    let userCoordinate: CLLocationCoordinate2D?
    let centerRequest: Int
    let fitRequest: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MLNMapView {
        let map = MLNMapView(
            frame: .zero,
            styleURL: URL(
                string: "https://tiles.openfreemap.org/styles/liberty"
            )
        )
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.tintColor = UIColor(
            red: 1, green: 0.34, blue: 0.09, alpha: 1
        )
        map.setCenter(
            CLLocationCoordinate2D(latitude: 44.05, longitude: 10.20),
            zoomLevel: 11.5,
            animated: false
        )
        return map
    }

    func updateUIView(_ map: MLNMapView, context: Context) {
        let coordinator = context.coordinator

        if coordinator.lastRouteID != routeID ||
            coordinator.lastRouteCount != routeCoordinates.count {
            coordinator.lastRouteID = routeID
            coordinator.lastRouteCount = routeCoordinates.count

            if let existing = coordinator.routeLine {
                map.removeAnnotation(existing)
                coordinator.routeLine = nil
            }

            var points = routeCoordinates.map(\.clLocationCoordinate)
            if points.count >= 2 {
                let line = MLNPolyline(
                    coordinates: &points,
                    count: UInt(points.count)
                )
                line.title = "ARET reference route"
                coordinator.routeLine = line
                map.addAnnotation(line)
            }

            if points.count >= 2 {
                coordinator.fit(route: points, on: map)
            }
        }

        if coordinator.lastRecordCount != recordedCoordinates.count {
            coordinator.lastRecordCount = recordedCoordinates.count
            if let existing = coordinator.recordingLine {
                map.removeAnnotation(existing)
                coordinator.recordingLine = nil
            }

            var points = recordedCoordinates
            if points.count >= 2 {
                let line = MLNPolyline(
                    coordinates: &points,
                    count: UInt(points.count)
                )
                line.title = "ARET recorded track"
                coordinator.recordingLine = line
                map.addAnnotation(line)
            }
        }

        if coordinator.lastCenterRequest != centerRequest {
            coordinator.lastCenterRequest = centerRequest
            if let userCoordinate {
                map.setCenter(
                    userCoordinate,
                    zoomLevel: 14.5,
                    animated: true
                )
            }
        }

        if coordinator.lastFitRequest != fitRequest {
            coordinator.lastFitRequest = fitRequest
            let points = routeCoordinates.map(\.clLocationCoordinate)
            if points.count >= 2 {
                coordinator.fit(route: points, on: map)
            } else if let userCoordinate {
                map.setCenter(
                    userCoordinate,
                    zoomLevel: 14.5,
                    animated: true
                )
            }
        }
    }

    final class Coordinator: NSObject, MLNMapViewDelegate {
        var routeLine: MLNPolyline?
        var recordingLine: MLNPolyline?
        var lastRouteID: String?
        var lastRouteCount = -1
        var lastRecordCount = -1
        var lastCenterRequest = 0
        var lastFitRequest = 0

        func mapView(
            _ mapView: MLNMapView,
            strokeColorForShapeAnnotation annotation: MLNShape
        ) -> UIColor {
            if annotation === recordingLine {
                return .white
            }
            return UIColor(red: 1, green: 0.34, blue: 0.09, alpha: 1)
        }

        func mapView(
            _ mapView: MLNMapView,
            lineWidthForPolylineAnnotation annotation: MLNPolyline
        ) -> CGFloat {
            annotation === recordingLine ? 3.5 : 5
        }

        func fit(
            route: [CLLocationCoordinate2D],
            on map: MLNMapView
        ) {
            guard route.count >= 2 else { return }
            let latitudes = route.map(\.latitude)
            let longitudes = route.map(\.longitude)
            guard
                let minLat = latitudes.min(),
                let maxLat = latitudes.max(),
                let minLon = longitudes.min(),
                let maxLon = longitudes.max()
            else { return }

            let bounds = MLNCoordinateBounds(
                sw: CLLocationCoordinate2D(
                    latitude: minLat,
                    longitude: minLon
                ),
                ne: CLLocationCoordinate2D(
                    latitude: maxLat,
                    longitude: maxLon
                )
            )
            map.setVisibleCoordinateBounds(
                bounds,
                edgePadding: UIEdgeInsets(
                    top: 90,
                    left: 40,
                    bottom: 295,
                    right: 40
                ),
                animated: true,
                completionHandler: nil
            )
        }
    }
}
