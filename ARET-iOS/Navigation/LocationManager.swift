import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var location: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var recordedLocations: [CLLocation] = []
    @Published private(set) var isTracking = false

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
        isTracking = true
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        isTracking = false
    }

    var distanceMeters: CLLocationDistance {
        zip(recordedLocations, recordedLocations.dropFirst())
            .reduce(0) { $0 + $1.0.distance(from: $1.1) }
    }

    var positiveElevationMeters: CLLocationDistance {
        zip(recordedLocations, recordedLocations.dropFirst())
            .reduce(0) { $0 + max(0, $1.1.altitude - $1.0.altitude) }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in authorizationStatus = manager.authorizationStatus }
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
