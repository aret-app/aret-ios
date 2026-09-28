import CoreLocation
import MapKit

public enum RouteDistanceCalculator {
    public static func distance(
        from coordinate: CLLocationCoordinate2D,
        to route: [ARETCoordinate]
    ) -> CLLocationDistance? {
        guard route.count >= 2 else { return nil }

        let point = MKMapPoint(coordinate)
        var minimumMapPointDistance = Double.greatestFiniteMagnitude

        for index in 0..<(route.count - 1) {
            let start = MKMapPoint(route[index].clLocationCoordinate)
            let end = MKMapPoint(route[index + 1].clLocationCoordinate)
            minimumMapPointDistance = min(
                minimumMapPointDistance,
                distanceFromPoint(point, toSegmentFrom: start, to: end)
            )
        }

        let metersPerMapPoint = MKMetersPerMapPointAtLatitude(coordinate.latitude)
        return minimumMapPointDistance * metersPerMapPoint
    }

    private static func distanceFromPoint(
        _ point: MKMapPoint,
        toSegmentFrom start: MKMapPoint,
        to end: MKMapPoint
    ) -> Double {
        let dx = end.x - start.x
        let dy = end.y - start.y

        guard dx != 0 || dy != 0 else {
            return hypot(point.x - start.x, point.y - start.y)
        }

        let t = max(
            0,
            min(
                1,
                ((point.x - start.x) * dx + (point.y - start.y) * dy) /
                (dx * dx + dy * dy)
            )
        )

        let projectedX = start.x + t * dx
        let projectedY = start.y + t * dy

        return hypot(point.x - projectedX, point.y - projectedY)
    }
}
