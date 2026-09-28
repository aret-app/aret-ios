import Foundation
import Combine

enum RouteOrigin: String, Hashable, Sendable {
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

    var libraryItem: RouteLibraryItem {
        RouteLibraryItem(
            id: id,
            name: name,
            subtitle: "Percorso personale",
            kind: kind,
            distanceKilometers: distanceKilometers,
            ascentMeters: ascentMeters,
            minimumAltitudeMeters: minimumAltitudeMeters,
            maximumAltitudeMeters: maximumAltitudeMeters,
            coordinates: coordinates,
            origin: .recordedActivity
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

        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        storeURL = directory.appendingPathComponent("saved-routes.json")
        load()

        // Deliberately do not restore an active route.
        // A route appears on the map only after the user selects it.
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
    func saveActivityAsRoute(_ activity: RecordedActivity) -> RouteLibraryItem? {
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
            coordinates: activity.points.map(\.aretCoordinate)
        )

        savedRouteRecords.insert(record, at: 0)
        persist()

        return record.libraryItem
    }

    func deletePersonalRoute(_ route: RouteLibraryItem) {
        guard route.origin == .recordedActivity else { return }

        savedRouteRecords.removeAll { $0.id == route.id }
        if activeRoute?.id == route.id {
            activeRoute = nil
        }
        persist()
    }

    private func load() {
        guard
            let data = try? Data(contentsOf: storeURL),
            let decoded = try? JSONDecoder().decode([SavedRouteRecord].self, from: data)
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
            try data.write(to: storeURL, options: .atomic)
        } catch {
            print("ARET route persistence error:", error.localizedDescription)
        }
    }
}
