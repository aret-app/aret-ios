import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var location: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var recordedLocations: [CLLocation] = []
    @Published private(set) var isTracking = false
    @Published private(set) var distanceMeters: CLLocationDistance = 0
    @Published private(set) var positiveElevationMeters: CLLocationDistance = 0
    @Published private(set) var negativeElevationMeters: CLLocationDistance = 0
    @Published private(set) var currentSpeedMPS: Double = 0
    @Published private(set) var maximumSpeedMPS: Double = 0
    @Published private(set) var trackingStartedAt: Date?

    @Published private(set) var hasIncompleteRecording = false
    @Published var recordingError: String?
    private let journal = RecordingJournal()
    private var pendingPoints: [RecordedTrackPoint] = []
    private let manager = CLLocationManager()

    private var lastRecordedLocation: CLLocation?
    private var elevationReference: Double?

    override init() {
        super.init()

        hasIncompleteRecording = journal.exists
        manager.delegate = self
        manager.activityType = .fitness

        // While browsing the map, do not consume navigation-grade GPS
        // power. Switch to dense tracking only for an active recording.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 25
        manager.pausesLocationUpdatesAutomatically = true

        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedAlways ||
            authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }

    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()

        default:
            break
        }
    }

    func startTracking(
        name: String = "Attività ARET",
        sourceRouteID: String? = nil
    ) {
        guard !isTracking else { return }
        guard !journal.exists else {
            hasIncompleteRecording = true
            return
        }
        let startedAt = Date()
        do {
            try journal.begin(name: name, startedAt: startedAt, sourceRouteID: sourceRouteID)
        } catch {
            hasIncompleteRecording = journal.exists
            recordingError = "Impossibile avviare il salvataggio GPS: \(error.localizedDescription)"
            return
        }

        recordedLocations.removeAll(keepingCapacity: true)
        distanceMeters = 0
        positiveElevationMeters = 0
        negativeElevationMeters = 0
        currentSpeedMPS = 0
        maximumSpeedMPS = 0
        lastRecordedLocation = nil
        elevationReference = nil
        trackingStartedAt = startedAt

        isTracking = true

        if let startedAt = trackingStartedAt {
            TrackingLiveActivityController
                .shared
                .start(
                    name: name,
                    startedAt: startedAt
                )
        }

        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
    }

    func stopTracking(
        name: String,
        sourceRouteID: String?
    ) -> RecordedActivity? {
        guard isTracking else { return nil }

        isTracking = false
        manager.allowsBackgroundLocationUpdates = false
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 25
        manager.pausesLocationUpdatesAutomatically = true

        let endedAt = Date()
        let startedAt = trackingStartedAt ?? recordedLocations.first?.timestamp ?? endedAt

        TrackingLiveActivityController
            .shared
            .end(
                distanceMeters: distanceMeters,
                ascentMeters: positiveElevationMeters,
                altitudeMeters: location?.altitude
            )

        do {
            try flushPendingPoints()
            guard !recordedLocations.isEmpty else {
                try journal.remove()
                resetRecordingState()
                return nil
            }
            let (header, _) = try journal.read()
            let filename = try saveRecordedTrackAsGPX(locations: recordedLocations, name: name, id: header.id)
            let activity = RecordedActivity(
                id: header.id, name: name, startedAt: startedAt, endedAt: endedAt,
                points: recordedLocations.map(RecordedTrackPoint.init(location:)),
                stats: .calculate(locations: recordedLocations, startedAt: startedAt, endedAt: endedAt),
                sourceRouteID: sourceRouteID, gpxFilename: filename
            )
            hasIncompleteRecording = true
            return activity
        } catch {
            hasIncompleteRecording = true
            recordingError = "Salvataggio incompleto. I punti restano recuperabili: \(error.localizedDescription)"
            return nil
        }
    }

    private func flushPendingPoints() throws {
        try journal.append(pendingPoints)
        pendingPoints.removeAll(keepingCapacity: true)
    }

    func recoverRecording() -> RecordedActivity? {
        guard !isTracking else { return nil }
        do {
            try flushPendingPoints()
            let (header, points) = try journal.read()
            guard !points.isEmpty else {
                recordingError = "La registrazione non contiene punti GPS recuperabili. I file sono conservati."
                return nil
            }
            let locations = points.map(\.location)
            let endedAt = points.last!.timestamp
            let filename = try saveRecordedTrackAsGPX(locations: locations, name: header.name, id: header.id)
            return RecordedActivity(
                id: header.id, name: header.name, startedAt: header.startedAt, endedAt: endedAt,
                points: points,
                stats: .calculate(locations: locations, startedAt: header.startedAt, endedAt: endedAt),
                sourceRouteID: header.sourceRouteID, gpxFilename: filename
            )
        } catch {
            recordingError = "Recupero non riuscito; file conservati: \(error.localizedDescription)"
            return nil
        }
    }

    func archiveIncompleteRecording() {
        guard !isTracking else { return }
        do {
            // Pending points must not disappear when archiving after a write failure.
            try flushPendingPoints()
            try journal.archive()
            resetRecordingState()
        } catch {
            recordingError = "Archiviazione non riuscita; registrazione conservata: \(error.localizedDescription)"
        }
    }

    func eraseRecordingData() -> Bool {
        guard !isTracking else {
            recordingError = "Termina la registrazione prima di eliminare i dati."
            return false
        }
        do {
            try journal.eraseAll()
            resetRecordingState()
            return true
        } catch {
            recordingError = "Eliminazione registrazioni non riuscita: \(error.localizedDescription)"
            return false
        }
    }

    private func resetRecordingState() {
        hasIncompleteRecording = false
        pendingPoints.removeAll()
        recordedLocations.removeAll()
        trackingStartedAt = nil
        lastRecordedLocation = nil
        elevationReference = nil
        distanceMeters = 0
        positiveElevationMeters = 0
        negativeElevationMeters = 0
        currentSpeedMPS = 0
        maximumSpeedMPS = 0
        recordingError = nil
    }

    // Called only after ActivityStore confirms the durable activity write.
    func confirmRecordingSaved() {
        do {
            try journal.remove()
            resetRecordingState()
        } catch {
            recordingError = "Attività salvata; pulizia registrazione da riprovare: \(error.localizedDescription)"
        }
    }

    private func acceptRecordedLocation(_ candidate: CLLocation) {
        guard candidate.horizontalAccuracy >= 0,
              candidate.horizontalAccuracy <= 50
        else {
            return
        }

        if let last = lastRecordedLocation {
            let deltaTime = candidate.timestamp.timeIntervalSince(last.timestamp)

            // Ignore duplicates/out-of-order callbacks.
            guard deltaTime > 0 else { return }

            let segmentDistance = candidate.distance(from: last)

            // Keep dense points like a navigation app, but avoid multiple
            // essentially identical samples in the same instant.
            guard deltaTime >= 0.75 || segmentDistance >= 1.0 else {
                return
            }

            let segmentSpeed = segmentDistance / deltaTime

            // Reject obvious GPS teleportation.
            if segmentSpeed <= 15 {
                distanceMeters += segmentDistance

                let measuredSpeed = candidate.speed >= 0
                    ? candidate.speed
                    : segmentSpeed

                currentSpeedMPS = measuredSpeed
                maximumSpeedMPS = max(
                    maximumSpeedMPS,
                    measuredSpeed
                )
            }
        }

        if candidate.verticalAccuracy >= 0,
           candidate.verticalAccuracy <= 50 {
            if let reference = elevationReference {
                let delta = candidate.altitude - reference

                // Hysteresis prevents altitude noise from becoming fake D+.
                if abs(delta) >= 2.5 {
                    if delta > 0 {
                        positiveElevationMeters += delta
                    } else {
                        negativeElevationMeters += abs(delta)
                    }
                    elevationReference = candidate.altitude
                }
            } else {
                elevationReference = candidate.altitude
            }
        }

        pendingPoints.append(RecordedTrackPoint(location: candidate))
        recordedLocations.append(candidate)
        lastRecordedLocation = candidate

        TrackingLiveActivityController
            .shared
            .update(
                distanceMeters: distanceMeters,
                ascentMeters: positiveElevationMeters,
                altitudeMeters: candidate.altitude
            )
    }

    private func saveRecordedTrackAsGPX(
        locations: [CLLocation],
        name: String,
        id: UUID
    ) throws -> String {
        let formatter = ISO8601DateFormatter()

        let points = locations.map { location in
            """
              <trkpt lat="\(location.coordinate.latitude)" lon="\(location.coordinate.longitude)">
                <ele>\(location.altitude)</ele>
                <time>\(formatter.string(from: location.timestamp))</time>
              </trkpt>
            """
        }
        .joined(separator: "\n")

        let escapedName = name
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="ARET"
             xmlns="http://www.topografix.com/GPX/1/1">
          <metadata>
            <name>\(escapedName)</name>
            <time>\(formatter.string(from: Date()))</time>
          </metadata>
          <trk>
            <name>\(escapedName)</name>
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

        let filename = "ARET_\(id.uuidString).gpx"
        let url = directory.appendingPathComponent(filename)

        guard let data = gpx.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }

        try PrivateStorage.writeProtected(data, to: url)
        return filename
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus

        Task { @MainActor [weak self] in
            guard let self else { return }

            authorizationStatus = status

            if status == .authorizedAlways || status == .authorizedWhenInUse {
                self.manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        Task { @MainActor in
            guard let newest = locations.last else { return }
            location = newest

            guard isTracking else { return }

            // Core Location may batch several valid samples. Keep all of them
            // instead of only the last one.
            for candidate in locations.sorted(by: { $0.timestamp < $1.timestamp }) {
                acceptRecordedLocation(candidate)
            }
            do {
                try flushPendingPoints()
            } catch {
                recordingError = "Salvataggio GPS sospeso; nuovo tentativo al prossimo aggiornamento: \(error.localizedDescription)"
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("ARET Core Location error:", error.localizedDescription)
    }
}
