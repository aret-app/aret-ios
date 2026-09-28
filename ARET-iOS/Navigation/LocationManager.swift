import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var location: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var recordedLocations: [CLLocation] = []
    @Published private(set) var isTracking = false
    @Published private(set) var lastRecordedGPXURL: URL?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        guard !isTracking else { return }
        recordedLocations.removeAll(keepingCapacity: true)
        lastRecordedGPXURL = nil
        isTracking = true
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        isTracking = false

        if recordedLocations.count > 1 {
            lastRecordedGPXURL = try? saveRecordedTrackAsGPX()
        }
    }

    var distanceMeters: CLLocationDistance {
        zip(recordedLocations, recordedLocations.dropFirst())
            .reduce(0) { $0 + $1.0.distance(from: $1.1) }
    }

    var positiveElevationMeters: CLLocationDistance {
        zip(recordedLocations, recordedLocations.dropFirst())
            .reduce(0) { $0 + max(0, $1.1.altitude - $1.0.altitude) }
    }

    private func saveRecordedTrackAsGPX() throws -> URL {
        let formatter = ISO8601DateFormatter()

        let points = recordedLocations.map { location in
            """
              <trkpt lat="\(location.coordinate.latitude)" lon="\(location.coordinate.longitude)">
                <ele>\(location.altitude)</ele>
                <time>\(formatter.string(from: location.timestamp))</time>
              </trkpt>
            """
        }
        .joined(separator: "\n")

        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="ARET"
             xmlns="http://www.topografix.com/GPX/1/1">
          <metadata>
            <name>ARET Recorded Track</name>
            <time>\(formatter.string(from: Date()))</time>
          </metadata>
          <trk>
            <name>ARET Recorded Track</name>
            <trkseg>
        \(points)
            </trkseg>
          </trk>
        </gpx>
        """

        let directory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let nameFormatter = DateFormatter()
        nameFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let filename = "ARET_\(nameFormatter.string(from: Date())).gpx"
        let url = directory.appendingPathComponent(filename)

        try gpx.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in authorizationStatus = status }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let newest = locations.last else { return }
            location = newest
            guard isTracking, newest.horizontalAccuracy >= 0, newest.horizontalAccuracy <= 50 else { return }
            recordedLocations.append(newest)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ARET Core Location error:", error.localizedDescription)
    }
}
