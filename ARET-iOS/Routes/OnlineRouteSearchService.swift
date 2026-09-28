import Foundation
import MapKit
import CoreLocation

@MainActor
final class OnlineRouteSearchService {
    static let shared = OnlineRouteSearchService()

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        return URLSession(configuration: configuration)
    }()

    private init() {}

    func search(
        query: String
    ) async throws -> [RouteLibraryItem] {
        let trimmed = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            return []
        }

        let center = try await geocode(
            query: trimmed
        )

        let overpassQuery = """
        [out:json][timeout:25];
        relation(around:25000,\(center.latitude),\(center.longitude))
          ["type"="route"]
          ["route"~"^(hiking|foot)$"];
        out tags center geom;
        """

        guard let url = URL(
            string:
                "https://overpass-api.de/api/interpreter"
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
            "ARET/0.1 (private field-test; OpenStreetMap route discovery)",
            forHTTPHeaderField: "User-Agent"
        )

        var form = URLComponents()
        form.queryItems = [
            URLQueryItem(
                name: "data",
                value: overpassQuery
            )
        ]

        request.httpBody =
            form.percentEncodedQuery?
                .data(using: .utf8)

        let (data, response) =
            try await session
                .data(for: request)

        guard
            let http =
                response as? HTTPURLResponse,
            200..<300 ~= http.statusCode
        else {
            throw URLError(
                .badServerResponse
            )
        }

        let decoded =
            try JSONDecoder().decode(
                OverpassResponse.self,
                from: data
            )

        let mapped = decoded.elements
            .compactMap {
                mapRelation(
                    $0,
                    searchCenter: center
                )
            }
            .sorted {
                $0.distanceFromSearchCenter <
                $1.distanceFromSearchCenter
            }
            .prefix(20)

        return mapped.map(\.route)
    }

    private func geocode(
        query: String
    ) async throws
        -> CLLocationCoordinate2D {
        let request =
            MKLocalSearch.Request()
        request.naturalLanguageQuery =
            query
        request.resultTypes = [
            .address,
            .pointOfInterest
        ]

        let response =
            try await MKLocalSearch(
                request: request
            ).start()

        guard let item =
                response.mapItems.first
        else {
            throw RouteSearchError
                .placeNotFound
        }

        return item.placemark.coordinate
    }

    private func mapRelation(
        _ relation: OverpassElement,
        searchCenter:
            CLLocationCoordinate2D
    ) -> MappedRoute? {
        guard
            let tags = relation.tags,
            let members = relation.members
        else {
            return nil
        }

        let segments =
            members.compactMap {
                member -> [ARETCoordinate]?
                in

                guard
                    member.type == "way",
                    let geometry =
                        member.geometry,
                    geometry.count > 1
                else {
                    return nil
                }

                var points =
                    geometry.map {
                        ARETCoordinate(
                            latitude:
                                $0.lat,
                            longitude:
                                $0.lon
                        )
                    }

                if member.role ==
                    "backward" {
                    points.reverse()
                }

                return points
            }

        guard !segments.isEmpty else {
            return nil
        }

        let coordinates =
            mergeSegments(segments)

        guard coordinates.count > 1
        else {
            return nil
        }

        let name =
            tags["name"] ??
            tags["ref"] ??
            "Percorso OSM"

        let ref = tags["ref"]
        let network =
            tags["network"]
        let operatorName =
            tags["operator"]

        let subtitleParts =
            [
                "OpenStreetMap",
                ref.map {
                    "sentiero \($0)"
                },
                network,
                operatorName
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }

        let distance =
            segmentDistance(
                segments
            )

        let route =
            RouteLibraryItem(
                id:
                    "osm-relation-\(relation.id)",
                name: name,
                subtitle:
                    subtitleParts
                    .joined(
                        separator: " · "
                    ),
                kind: .hiking,
                distanceKilometers:
                    distance / 1000,
                ascentMeters: 0,
                minimumAltitudeMeters: 0,
                maximumAltitudeMeters: 0,
                coordinates:
                    coordinates,
                origin:
                    .openStreetMap
            )

        let routeCenter =
            relation.center.map {
                CLLocationCoordinate2D(
                    latitude: $0.lat,
                    longitude: $0.lon
                )
            } ??
            coordinates[
                coordinates.count / 2
            ].clLocationCoordinate

        let centerLocation =
            CLLocation(
                latitude:
                    searchCenter.latitude,
                longitude:
                    searchCenter.longitude
            )

        let routeLocation =
            CLLocation(
                latitude:
                    routeCenter.latitude,
                longitude:
                    routeCenter.longitude
            )

        return MappedRoute(
            route: route,
            distanceFromSearchCenter:
                routeLocation.distance(
                    from: centerLocation
                )
        )
    }

    private func mergeSegments(
        _ segments:
            [[ARETCoordinate]]
    ) -> [ARETCoordinate] {
        guard var merged =
                segments.first
        else {
            return []
        }

        for segment in
            segments.dropFirst() {
            guard
                let currentEnd =
                    merged.last,
                let first =
                    segment.first,
                let last =
                    segment.last
            else {
                continue
            }

            let endLocation =
                CLLocation(
                    latitude:
                        currentEnd.latitude,
                    longitude:
                        currentEnd.longitude
                )

            let firstDistance =
                endLocation.distance(
                    from: CLLocation(
                        latitude:
                            first.latitude,
                        longitude:
                            first.longitude
                    )
                )

            let lastDistance =
                endLocation.distance(
                    from: CLLocation(
                        latitude:
                            last.latitude,
                        longitude:
                            last.longitude
                    )
                )

            var oriented = segment

            if lastDistance <
                firstDistance {
                oriented.reverse()
            }

            if let orientedFirst =
                oriented.first,
               currentEnd.latitude ==
                orientedFirst.latitude,
               currentEnd.longitude ==
                orientedFirst.longitude {
                merged.append(
                    contentsOf:
                        oriented.dropFirst()
                )
            } else {
                merged.append(
                    contentsOf: oriented
                )
            }
        }

        return merged
    }

    private func segmentDistance(
        _ segments:
            [[ARETCoordinate]]
    ) -> CLLocationDistance {
        var total = 0.0

        for segment in segments {
            for (first, second) in
                zip(
                    segment,
                    segment.dropFirst()
                ) {
                let firstLocation =
                    CLLocation(
                        latitude:
                            first.latitude,
                        longitude:
                            first.longitude
                    )

                let secondLocation =
                    CLLocation(
                        latitude:
                            second.latitude,
                        longitude:
                            second.longitude
                    )

                total +=
                    secondLocation.distance(
                        from:
                            firstLocation
                    )
            }
        }

        return total
    }
}

private struct MappedRoute {
    let route: RouteLibraryItem
    let distanceFromSearchCenter:
        CLLocationDistance
}

private struct OverpassResponse:
    Decodable {
    let elements:
        [OverpassElement]
}

private struct OverpassElement:
    Decodable {
    let id: Int64
    let tags:
        [String: String]?
    let center:
        OverpassPoint?
    let members:
        [OverpassMember]?
}

private struct OverpassMember:
    Decodable {
    let type: String
    let role: String?
    let geometry:
        [OverpassPoint]?
}

private struct OverpassPoint:
    Decodable {
    let lat: Double
    let lon: Double
}

private enum RouteSearchError:
    LocalizedError {
    case placeNotFound

    var errorDescription:
        String? {
        switch self {
        case .placeNotFound:
            return
                "Non riesco a localizzare questa montagna o località."
        }
    }
}
