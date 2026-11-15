import Foundation
import MapKit
import CoreLocation

/// Discovers complete OSM hiking/ferrata relations near a named summit.
/// A disconnected relation is discarded instead of drawing a false shortcut.
@MainActor
final class OnlineRouteSearchService {
    static let shared = OnlineRouteSearchService()

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 35
        configuration.timeoutIntervalForResource = 45
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        return URLSession(configuration: configuration)
    }()

    private init() {}

    func search(query: String) async throws -> [RouteLibraryItem] {
        try await discover(query: query).routes
    }

    func discover(query: String) async throws -> MountainRouteSearchResult {
        let trimmed = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty else {
            return MountainRouteSearchResult(routes: [], technicalSegments: [])
        }

        let geocodingQuery =
            MountainAscentLibrary.preferredSearchCenter(for: trimmed)
            ?? trimmed

        let center = try await geocode(query: geocodingQuery)
        let overpassQuery = """
        [out:json][timeout:30];
        (
          relation(around:12000,\(center.latitude),\(center.longitude))
            ["type"="route"]["route"~"^(hiking|foot|via_ferrata)$"];
          way(around:5000,\(center.latitude),\(center.longitude))
            ["highway"="via_ferrata"];
          way(around:5000,\(center.latitude),\(center.longitude))
            ["via_ferrata_scale"];
        );
        out tags center geom;
        """

        guard let url = URL(
            string: "https://overpass-api.de/api/interpreter"
        ) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue(
            "ARET-Hiking/0.2 (route discovery; contact through ARET project)",
            forHTTPHeaderField: "User-Agent"
        )

        var form = URLComponents()
        form.queryItems = [
            URLQueryItem(name: "data", value: overpassQuery)
        ]
        request.httpBody = form.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard
            let http = response as? HTTPURLResponse,
            200..<300 ~= http.statusCode
        else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(
            OverpassResponse.self,
            from: data
        )

        let results = decoded.elements.filter {
            $0.type == "relation"
        }.compactMap { relation in
            mapRelation(
                relation,
                searchCenter: center,
                query: trimmed
            )
        }
        .sorted {
            if $0.nameMatch != $1.nameMatch {
                return $0.nameMatch && !$1.nameMatch
            }
            return $0.nearestDistance < $1.nearestDistance
        }
        .prefix(35)

        let technicalSegments = decoded.elements
            .filter { $0.type == "way" }
            .compactMap { mapTechnicalSegment($0) }
            .sorted { $0.name < $1.name }

        // Both whole route relations and isolated ferrata sections are
        // displayed, with different labels and NO invented connectors.
        return MountainRouteSearchResult(
            routes: results.map(\.route),
            technicalSegments: Array(technicalSegments.prefix(15))
        )
    }

    private func mapTechnicalSegment(
        _ way: OverpassElement
    ) -> OSMTechnicalSegment? {
        guard
            let raw = way.geometry,
            raw.count >= 2,
            let tags = way.tags
        else { return nil }

        let points = raw.compactMap { point -> ARETCoordinate? in
            guard
                (-90...90).contains(point.lat),
                (-180...180).contains(point.lon)
            else { return nil }
            return ARETCoordinate(
                latitude: point.lat,
                longitude: point.lon
            )
        }

        guard points.count >= 2 else { return nil }

        return OSMTechnicalSegment(
            id: "osm-ferrata-way-\(way.id)",
            name: tags["name:it"] ?? tags["name"] ??
                "Tratto di via ferrata",
            difficulty: tags["via_ferrata_scale"].map {
                "Scala OSM \($0) — da verificare"
            } ?? "Difficoltà non riportata su OSM",
            points: points,
            sourceURL: URL(
                string: "https://www.openstreetmap.org/way/\(way.id)"
            )!
        )
    }

    private func geocode(
        query: String
    ) async throws -> CLLocationCoordinate2D {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]

        let response = try await MKLocalSearch(
            request: request
        ).start()

        guard let coordinate =
            response.mapItems.first?.placemark.coordinate
        else {
            throw RouteSearchError.placeNotFound
        }
        return coordinate
    }

    private func mapRelation(
        _ relation: OverpassElement,
        searchCenter: CLLocationCoordinate2D,
        query: String
    ) -> MappedRoute? {
        guard
            let tags = relation.tags,
            let members = relation.members,
            let routeType = tags["route"],
            ["hiking", "foot", "via_ferrata"].contains(routeType)
        else {
            return nil
        }

        // OSM relation members are not guaranteed to be ordered. Greedy
        // endpoint chaining is a safe beta approximation: reject gaps,
        // branches or incomplete relations rather than joining by straight
        // lines through cliffs, private land or exposed terrain.
        let segments = members.compactMap { member -> [ARETCoordinate]? in
            guard
                member.type == "way",
                let geometry = member.geometry,
                geometry.count >= 2
            else { return nil }

            var points = geometry.compactMap { point -> ARETCoordinate? in
                guard
                    (-90...90).contains(point.lat),
                    (-180...180).contains(point.lon)
                else { return nil }

                return ARETCoordinate(
                    latitude: point.lat,
                    longitude: point.lon
                )
            }

            guard points.count >= 2 else { return nil }
            if member.role == "backward" {
                points.reverse()
            }
            return points
        }

        guard
            !segments.isEmpty,
            let coordinates = stitchIfContinuous(segments),
            coordinates.count >= 2
        else {
            return nil
        }

        let center = CLLocation(
            latitude: searchCenter.latitude,
            longitude: searchCenter.longitude
        )
        let nearestDistance = coordinates.map {
            CLLocation(
                latitude: $0.latitude,
                longitude: $0.longitude
            ).distance(from: center)
        }.min() ?? .greatestFiniteMagnitude

        // A relation merely passing through the surrounding 12km zone
        // need not be an ascent to the summit. Prefer actual nearby lines.
        guard nearestDistance <= 6_500 else { return nil }

        let name = tags["name:it"]
            ?? tags["name"]
            ?? tags["ref"]
            ?? (routeType == "via_ferrata"
                ? "Ferrata OSM senza nome"
                : "Percorso OSM senza nome")

        let isFerrata = routeType == "via_ferrata"
        let difficulty = documentedDifficulty(
            tags: tags,
            isFerrata: isFerrata
        )

        let parts: [String?] = [
            isFerrata ? "Via ferrata" : "Escursionismo",
            difficulty,
            tags["ref"].map { "ref \($0)" },
            "OpenStreetMap · non verificato da ARET"
        ]

        let distanceMeters = totalDistance(of: coordinates)
        let route = RouteLibraryItem(
            id: "osm-relation-\(relation.id)",
            name: name,
            subtitle: parts.compactMap { $0 }.joined(separator: " · "),
            kind: isFerrata ? .alpine : .hiking,
            distanceKilometers: distanceMeters / 1_000,
            ascentMeters: 0,
            minimumAltitudeMeters: 0,
            maximumAltitudeMeters: 0,
            coordinates: coordinates,
            origin: .openStreetMap
        )

        let normalizedQuery = query.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "it_IT")
        )
        let normalizedName = name.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "it_IT")
        )

        return MappedRoute(
            route: route,
            nearestDistance: nearestDistance,
            nameMatch: normalizedName.contains(normalizedQuery) ||
                normalizedQuery.contains(normalizedName)
        )
    }

    private func documentedDifficulty(
        tags: [String: String],
        isFerrata: Bool
    ) -> String? {
        if isFerrata {
            if let scale = tags["via_ferrata_scale"] {
                return "scala ferrata OSM \(scale) (da verificare)"
            }
            return "difficoltà ferrata non indicata"
        }

        let descriptions = [
            "hiking": "T",
            "mountain_hiking": "E indicativo",
            "demanding_mountain_hiking": "EE indicativo",
            "alpine_hiking": "terreno alpino",
            "demanding_alpine_hiking": "alpino impegnativo",
            "difficult_alpine_hiking": "alpino molto impegnativo"
        ]

        guard let scale = tags["sac_scale"] else {
            return "difficoltà non specificata"
        }

        return "SAC \(scale) · \(descriptions[scale] ?? "scala OSM")"
    }

    /// OSM can provide a route in arbitrary member order. We accept only
    /// lines for which endpoints can be chained within 3m. Larger
    /// gaps must never be silently bridged by a straight-line segment.
    private func stitchIfContinuous(
        _ segments: [[ARETCoordinate]]
    ) -> [ARETCoordinate]? {
        guard var first = segments.first else { return nil }
        var unused = Array(segments.dropFirst())
        let tolerance = 3.0

        while !unused.isEmpty {
            guard let end = first.last else { return nil }
            let endLocation = CLLocation(
                latitude: end.latitude,
                longitude: end.longitude
            )

            var bestIndex: Int?
            var reverse = false
            var bestDistance = Double.greatestFiniteMagnitude

            for (index, segment) in unused.enumerated() {
                guard
                    let head = segment.first,
                    let tail = segment.last
                else { continue }

                let headDistance = endLocation.distance(from: CLLocation(
                    latitude: head.latitude,
                    longitude: head.longitude
                ))
                let tailDistance = endLocation.distance(from: CLLocation(
                    latitude: tail.latitude,
                    longitude: tail.longitude
                ))

                if min(headDistance, tailDistance) < bestDistance {
                    bestIndex = index
                    bestDistance = min(headDistance, tailDistance)
                    reverse = tailDistance < headDistance
                }
            }

            guard let bestIndex, bestDistance <= tolerance else {
                return nil
            }

            var segment = unused.remove(at: bestIndex)
            if reverse { segment.reverse() }
            // Only merge endpoints, never insert fictional traverses.
            if bestDistance <= tolerance {
                first.append(contentsOf: segment.dropFirst())
            }
        }

        return first
    }

    private func totalDistance(
        of coordinates: [ARETCoordinate]
    ) -> CLLocationDistance {
        zip(coordinates, coordinates.dropFirst()).reduce(0) {
            result, pair in
            result + CLLocation(
                latitude: pair.0.latitude,
                longitude: pair.0.longitude
            ).distance(
                from: CLLocation(
                    latitude: pair.1.latitude,
                    longitude: pair.1.longitude
                )
            )
        }
    }
}

struct MountainRouteSearchResult {
    let routes: [RouteLibraryItem]
    let technicalSegments: [OSMTechnicalSegment]
}

struct OSMTechnicalSegment: Identifiable, Hashable {
    let id: String
    let name: String
    let difficulty: String
    let points: [ARETCoordinate]
    let sourceURL: URL
}

private struct MappedRoute {
    let route: RouteLibraryItem
    let nearestDistance: CLLocationDistance
    let nameMatch: Bool
}

private struct OverpassResponse: Decodable {
    let elements: [OverpassElement]
}

private struct OverpassElement: Decodable {
    let type: String
    let id: Int64
    let tags: [String: String]?
    let members: [OverpassMember]?
    let geometry: [OverpassPoint]?
}

private struct OverpassMember: Decodable {
    let type: String
    let role: String?
    let geometry: [OverpassPoint]?
}

private struct OverpassPoint: Decodable {
    let lat: Double
    let lon: Double
}

private enum RouteSearchError: LocalizedError {
    case placeNotFound

    var errorDescription: String? {
        switch self {
        case .placeNotFound:
            return "Non riesco a localizzare questa cima o via."
        }
    }
}
