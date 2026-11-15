import Foundation
import MapKit
import CoreLocation

/// Discovery scope for the ARET Hiking pilot. Rectangles are intentionally
/// broad search windows, NOT official national/regional park boundaries.
/// Geographic inclusion does not certify any route or summit.
enum ARETPilotRegion: String, CaseIterable, Identifiable, Sendable {
    case apuane
    case appennino

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apuane: return "Alpi Apuane"
        case .appennino: return "Appennino tosco-emiliano"
        }
    }

    var south: Double {
        switch self {
        case .apuane: return 43.84
        case .appennino: return 43.90
        }
    }

    var north: Double {
        switch self {
        case .apuane: return 44.37
        case .appennino: return 44.75
        }
    }

    var west: Double {
        switch self {
        case .apuane: return 9.92
        case .appennino: return 9.34
        }
    }

    var east: Double {
        switch self {
        case .apuane: return 10.58
        case .appennino: return 11.33
        }
    }

    var searchCenter: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: (south + north) / 2,
            longitude: (west + east) / 2
        )
    }

    var mapRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: searchCenter,
            span: MKCoordinateSpan(
                latitudeDelta: (north - south) * 1.15,
                longitudeDelta: (east - west) * 1.15
            )
        )
    }

    var overpassBoundingBox: String {
        "\(south),\(west),\(north),\(east)"
    }

    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        (south...north).contains(coordinate.latitude) &&
            (west...east).contains(coordinate.longitude)
    }

    /// These are search shortcuts, NOT verified ascent guides or GPX routes.
    var suggestedSummits: [String] {
        switch self {
        case .apuane:
            return [
                "Monte Pisanino",
                "Pizzo d'Uccello",
                "Monte Grondilice",
                "Monte Sagro",
                "Monte Roccandagia",
                "Monte Tambura",
                "Monte Sella",
                "Monte Cavallo",
                "Monte Contrario",
                "Monte Sumbra",
                "Monte Altissimo",
                "Monte Corchia",
                "Pania della Croce",
                "Pania Secca",
                "Pizzo delle Saette",
                "Monte Forato",
                "Monte Procinto",
                "Monte Matanna",
                "Monte Gabberi",
                "Monte Freddone",
                "Monte Nona",
                "Monte Fiocca",
                "Monte Borla"
            ]
        case .appennino:
            return [
                "Monte Cusna",
                "Monte Prado",
                "Alpe di Succiso",
                "Monte Marmagna",
                "Monte Orsaro",
                "Monte Sillara",
                "Monte Ventasso",
                "Monte la Nuda",
                "Monte Giovo",
                "Monte Rondinaio",
                "Monte Cimone",
                "Corno alle Scale",
                "Monte Libro Aperto",
                "Monte Spigolino",
                "Monte Gennaio",
                "Monte Sillano",
                "Monte Romecchio",
                "Monte Acuto",
                "Pania di Corfino",
                "Pietra di Bismantova"
            ]
        }
    }
}

enum ARETDiscoveryScope: String, CaseIterable, Identifiable, Sendable {
    case both
    case apuane
    case appennino

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .both: return "Entrambe"
        case .apuane: return "Apuane"
        case .appennino: return "Appennino"
        }
    }

    var regions: [ARETPilotRegion] {
        switch self {
        case .both: return [.apuane, .appennino]
        case .apuane: return [.apuane]
        case .appennino: return [.appennino]
        }
    }

    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        regions.contains { $0.contains(coordinate) }
    }

    var suggestedSummits: [String] {
        regions.flatMap(\.suggestedSummits)
    }
}
