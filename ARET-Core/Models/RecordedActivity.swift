import Foundation
import CoreLocation

public struct RecordedTrackPoint: Codable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double
    public let timestamp: Date
    public let horizontalAccuracy: Double
    public let verticalAccuracy: Double
    public let speed: Double

    public init(location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        altitude = location.altitude
        timestamp = location.timestamp
        horizontalAccuracy = location.horizontalAccuracy
        verticalAccuracy = location.verticalAccuracy
        speed = location.speed
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var aretCoordinate: ARETCoordinate {
        ARETCoordinate(
            latitude: latitude,
            longitude: longitude,
            altitude: altitude
        )
    }

    public var location: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            timestamp: timestamp
        )
    }
}

public struct ActivityStats: Codable, Hashable, Sendable {
    public let distanceMeters: Double
    public let ascentMeters: Double
    public let descentMeters: Double
    public let minimumAltitudeMeters: Double
    public let maximumAltitudeMeters: Double
    public let durationSeconds: Double
    public let movingTimeSeconds: Double
    public let averageMovingSpeedMPS: Double
    public let maximumSpeedMPS: Double
    public let pointCount: Int

    public static func calculate(
        locations: [CLLocation],
        startedAt: Date,
        endedAt: Date
    ) -> ActivityStats {
        guard !locations.isEmpty else {
            return ActivityStats(
                distanceMeters: 0,
                ascentMeters: 0,
                descentMeters: 0,
                minimumAltitudeMeters: 0,
                maximumAltitudeMeters: 0,
                durationSeconds: max(0, endedAt.timeIntervalSince(startedAt)),
                movingTimeSeconds: 0,
                averageMovingSpeedMPS: 0,
                maximumSpeedMPS: 0,
                pointCount: 0
            )
        }

        var distance = 0.0
        var movingTime = 0.0
        var maximumSpeed = 0.0

        for (first, second) in zip(locations, locations.dropFirst()) {
            let deltaTime = second.timestamp.timeIntervalSince(first.timestamp)
            guard deltaTime > 0, deltaTime <= 60 else { continue }

            let segmentDistance = second.distance(from: first)
            let segmentSpeed = segmentDistance / deltaTime

            // Reject impossible GPS jumps while retaining fast hiking/running data.
            guard segmentSpeed <= 15 else { continue }

            distance += segmentDistance
            maximumSpeed = max(maximumSpeed, segmentSpeed)

            if segmentSpeed >= 0.3 {
                movingTime += deltaTime
            }
        }

        let altitudeLocations = locations.filter {
            $0.verticalAccuracy >= 0 && $0.verticalAccuracy <= 50
        }

        let altitudes = altitudeLocations.map(\.altitude)
        let minimumAltitude = altitudes.min() ?? locations.map(\.altitude).min() ?? 0
        let maximumAltitude = altitudes.max() ?? locations.map(\.altitude).max() ?? 0

        var ascent = 0.0
        var descent = 0.0

        if let firstAltitude = altitudeLocations.first?.altitude {
            var elevationReference = firstAltitude

            for location in altitudeLocations.dropFirst() {
                let delta = location.altitude - elevationReference

                // Small GPS altitude oscillations should not inflate D+/D-.
                if abs(delta) >= 2.5 {
                    if delta > 0 {
                        ascent += delta
                    } else {
                        descent += abs(delta)
                    }
                    elevationReference = location.altitude
                }
            }
        }

        let duration = max(0, endedAt.timeIntervalSince(startedAt))
        let averageMovingSpeed = movingTime > 0 ? distance / movingTime : 0

        return ActivityStats(
            distanceMeters: distance,
            ascentMeters: ascent,
            descentMeters: descent,
            minimumAltitudeMeters: minimumAltitude,
            maximumAltitudeMeters: maximumAltitude,
            durationSeconds: duration,
            movingTimeSeconds: movingTime,
            averageMovingSpeedMPS: averageMovingSpeed,
            maximumSpeedMPS: maximumSpeed,
            pointCount: locations.count
        )
    }
}

public struct RecordedActivity: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public let startedAt: Date
    public let endedAt: Date
    public let points: [RecordedTrackPoint]
    public let stats: ActivityStats
    public var sourceRouteID: String?
    public var gpxFilename: String?

    public init(
        id: UUID = UUID(),
        name: String,
        startedAt: Date,
        endedAt: Date,
        points: [RecordedTrackPoint],
        stats: ActivityStats,
        sourceRouteID: String? = nil,
        gpxFilename: String? = nil
    ) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.points = points
        self.stats = stats
        self.sourceRouteID = sourceRouteID
        self.gpxFilename = gpxFilename
    }

    public static func make(
        name: String,
        startedAt: Date,
        endedAt: Date,
        locations: [CLLocation],
        sourceRouteID: String?,
        gpxFilename: String?
    ) -> RecordedActivity {
        RecordedActivity(
            name: name,
            startedAt: startedAt,
            endedAt: endedAt,
            points: locations.map(RecordedTrackPoint.init(location:)),
            stats: .calculate(
                locations: locations,
                startedAt: startedAt,
                endedAt: endedAt
            ),
            sourceRouteID: sourceRouteID,
            gpxFilename: gpxFilename
        )
    }
}
