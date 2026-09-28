import Foundation
import Combine
import CoreLocation

enum RouteOrigin: String, Codable, Hashable, Sendable {
    case aretCatalog
    case recordedActivity
    case importedGPX
}

struct RouteLibraryItem: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var subtitle: String
    var kind: RouteKind
    var distanceKilometers: Double
    var ascentMeters: Int
    var minimumAltitudeMeters: Int
    var maximumAltitudeMeters: Int
    var coordinates: [ARETCoordinate]
    var origin: RouteOrigin
}

private struct SavedRouteRecord: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var createdAt: Date
    var kind: RouteKind
    var distanceKilometers: Double
    var ascentMeters: Int
    var minimumAltitudeMeters: Int
    var maximumAltitudeMeters: Int
    var coordinates: [ARETCoordinate]

    // Optional for backwards compatibility with already-saved beta data.
    var origin: RouteOrigin?
    var subtitle: String?

    var libraryItem: RouteLibraryItem {
        let resolvedOrigin = origin ?? .recordedActivity

        return RouteLibraryItem(
            id: id,
            name: name,
            subtitle: subtitle ?? (
                resolvedOrigin == .importedGPX
                ? "GPX importato"
                : "Percorso personale"
            ),
            kind: kind,
            distanceKilometers: distanceKilometers,
            ascentMeters: ascentMeters,
            minimumAltitudeMeters: minimumAltitudeMeters,
            maximumAltitudeMeters: maximumAltitudeMeters,
            coordinates: coordinates,
            origin: resolvedOrigin
        )
    }
}

@MainActor
final class RouteLibraryStore: ObservableObject {
    @Published var activeRoute: RouteLibraryItem?
    @Published private var savedRouteRecords: [SavedRouteRecord] = []

    private let storeURL: URL

    init() {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        .appendingPathComponent("ARET", isDirectory: true)

        try? PrivateStorage.prepareDirectory(directory)

        storeURL = directory.appendingPathComponent("saved-routes.json")
        try? PrivateStorage.hardenExistingFile(storeURL)
        load()

        // A route appears on the map only after an explicit user selection.
        activeRoute = nil
    }

    var catalogRoutes: [RouteLibraryItem] {
        BuiltInRouteCatalog.routes.map { route in
            RouteLibraryItem(
                id: route.id,
                name: route.name,
                subtitle: route.subtitle,
                kind: route.kind,
                distanceKilometers: route.distanceKilometers,
                ascentMeters: route.ascentMeters,
                minimumAltitudeMeters: route.minimumAltitudeMeters,
                maximumAltitudeMeters: route.maximumAltitudeMeters,
                coordinates: route.coordinates.map {
                    ARETCoordinate(
                        latitude: $0.latitude,
                        longitude: $0.longitude
                    )
                },
                origin: .aretCatalog
            )
        }
    }

    var personalRoutes: [RouteLibraryItem] {
        savedRouteRecords.map(\.libraryItem)
    }

    func select(_ route: RouteLibraryItem) {
        activeRoute = route
    }

    func clearSelection() {
        activeRoute = nil
    }

    @discardableResult
    func saveActivityAsRoute(
        _ activity: RecordedActivity
    ) -> RouteLibraryItem? {
        guard activity.points.count > 1 else { return nil }

        let id = "recorded-\(activity.id.uuidString)"

        if let existing = savedRouteRecords.first(where: { $0.id == id }) {
            return existing.libraryItem
        }

        let stats = activity.stats

        let record = SavedRouteRecord(
            id: id,
            name: activity.name,
            createdAt: Date(),
            kind: .hiking,
            distanceKilometers: stats.distanceMeters / 1000,
            ascentMeters: Int(stats.ascentMeters.rounded()),
            minimumAltitudeMeters: Int(stats.minimumAltitudeMeters.rounded()),
            maximumAltitudeMeters: Int(stats.maximumAltitudeMeters.rounded()),
            coordinates: activity.points.map(\.aretCoordinate),
            origin: .recordedActivity,
            subtitle: "Percorso personale"
        )

        savedRouteRecords.insert(record, at: 0)
        persist()

        return record.libraryItem
    }

    @discardableResult
    func saveImportedGPX(
        name: String,
        coordinates: [ARETCoordinate]
    ) -> RouteLibraryItem? {
        guard coordinates.count > 1 else { return nil }

        let stats = routeStats(for: coordinates)

        let record = SavedRouteRecord(
            id: "imported-\(UUID().uuidString)",
            name: name,
            createdAt: Date(),
            kind: .hiking,
            distanceKilometers: stats.distance / 1000,
            ascentMeters: Int(stats.ascent.rounded()),
            minimumAltitudeMeters: Int(stats.minimumAltitude.rounded()),
            maximumAltitudeMeters: Int(stats.maximumAltitude.rounded()),
            coordinates: coordinates,
            origin: .importedGPX,
            subtitle: "GPX importato"
        )

        savedRouteRecords.insert(record, at: 0)
        persist()

        // Do not activate it automatically.
        return record.libraryItem
    }

    func deleteAllPersonalRoutes() {
        savedRouteRecords.removeAll()
        activeRoute = nil
        try? FileManager.default.removeItem(at: storeURL)
    }

    func deletePersonalRoute(_ route: RouteLibraryItem) {
        guard route.origin != .aretCatalog else { return }

        savedRouteRecords.removeAll { $0.id == route.id }

        if activeRoute?.id == route.id {
            activeRoute = nil
        }

        persist()
    }

    private func routeStats(
        for coordinates: [ARETCoordinate]
    ) -> (
        distance: Double,
        ascent: Double,
        minimumAltitude: Double,
        maximumAltitude: Double
    ) {
        var distance = 0.0

        for (first, second) in zip(coordinates, coordinates.dropFirst()) {
            let firstLocation = CLLocation(
                latitude: first.latitude,
                longitude: first.longitude
            )
            let secondLocation = CLLocation(
                latitude: second.latitude,
                longitude: second.longitude
            )

            distance += secondLocation.distance(from: firstLocation)
        }

        let altitudePoints = coordinates.compactMap { coordinate -> Double? in
            coordinate.altitude
        }

        var ascent = 0.0

        if let firstAltitude = altitudePoints.first {
            var reference = firstAltitude

            for altitude in altitudePoints.dropFirst() {
                let delta = altitude - reference

                if abs(delta) >= 2.5 {
                    if delta > 0 {
                        ascent += delta
                    }
                    reference = altitude
                }
            }
        }

        return (
            distance,
            ascent,
            altitudePoints.min() ?? 0,
            altitudePoints.max() ?? 0
        )
    }

    private func load() {
        guard
            let data = try? Data(contentsOf: storeURL),
            let decoded = try? JSONDecoder().decode(
                [SavedRouteRecord].self,
                from: data
            )
        else {
            savedRouteRecords = []
            return
        }

        savedRouteRecords = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(savedRouteRecords)
            try PrivateStorage.writeProtected(data, to: storeURL)
        } catch {
            print(
                "ARET route persistence error:",
                error.localizedDescription
            )
        }
    }
}
