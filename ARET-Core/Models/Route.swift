import Foundation
import CoreLocation

public struct ARETCoordinate: Codable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double?

    public init(latitude: Double, longitude: Double, altitude: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }

    public var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

public enum RouteKind: String, Codable, CaseIterable, Sendable {
    case hiking
    case sportClimbing
    case multipitch
    case alpine
    case ice
    case glacier
    case indoor
}

public struct RouteFeature: Identifiable, Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case start, bolt, anchor, pitch, crux, rappel, protection, hazard, waypoint, finish
    }

    public let id: UUID
    public let kind: Kind
    public let coordinate: ARETCoordinate
    public var title: String
    public var note: String?
    public var pitchNumber: Int?

    public init(
        id: UUID = UUID(),
        kind: Kind,
        coordinate: ARETCoordinate,
        title: String,
        note: String? = nil,
        pitchNumber: Int? = nil
    ) {
        self.id = id
        self.kind = kind
        self.coordinate = coordinate
        self.title = title
        self.note = note
        self.pitchNumber = pitchNumber
    }
}

public struct ARETRoute: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var area: String
    public var kind: RouteKind
    public var difficulty: String?
    public var coordinates: [ARETCoordinate]
    public var features: [RouteFeature]

    public init(
        id: UUID = UUID(),
        name: String,
        area: String,
        kind: RouteKind,
        difficulty: String? = nil,
        coordinates: [ARETCoordinate],
        features: [RouteFeature] = []
    ) {
        self.id = id
        self.name = name
        self.area = area
        self.kind = kind
        self.difficulty = difficulty
        self.coordinates = coordinates
        self.features = features
    }
}
