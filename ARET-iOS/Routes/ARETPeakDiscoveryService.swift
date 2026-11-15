import Foundation
import CoreLocation

/// A named OSM summit/place for discovery, not a verified ascent.
/// Never fabricate a route from a peak's coordinate.
struct ARETPeak: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let region: ARETPilotRegion
    let latitude: Double
    let longitude: Double
    let elevationMeters: Double?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }

    var osmURL: URL? {
        URL(string: "https://www.openstreetmap.org/node/\(id)")
    }

    var subtitle: String {
        let altitude = elevationMeters.map {
            " · \(Int($0.rounded())) m"
        } ?? ""
        return region.displayName + altitude + " · OpenStreetMap"
    }
}

struct ARETPeakLookup {
    let peaks: [ARETPeak]
    let failedRegions: [ARETPilotRegion]
    let isFromCache: Bool
}

/// On-demand region summit index from OSM Overpass.
/// The public API is for prototyping and rate limited; move discovery
/// behind our own cached backend before a significant release.
@MainActor
final class ARETPeakDiscoveryService {
    static let shared = ARETPeakDiscoveryService()

    private struct CacheEntry {
        let retrievedAt: Date
        let peaks: [ARETPeak]
    }

    private var cache: [ARETPilotRegion: CacheEntry] = [:]
    private var ongoing: [ARETPilotRegion: Task<[ARETPeak], Error>] = [:]

    private let cacheLifetime: TimeInterval = 6 * 60 * 60

    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 40
        config.timeoutIntervalForResource = 50
        return URLSession(configuration: config)
    }()

    private init() {}

    func cachedPeaks(in scope: ARETDiscoveryScope) -> [ARETPeak] {
        scope.regions.flatMap { cache[$0]?.peaks ?? [] }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func exactOrCloseMatch(
        query: String,
        scope: ARETDiscoveryScope
    ) -> ARETPeak? {
        let queryKey = Self.normalize(query)
        guard queryKey.count >= 4 else { return nil }

        let candidates = cachedPeaks(in: scope)
        if let exact = candidates.first(where: {
            Self.normalize($0.name) == queryKey
        }) {
            return exact
        }

        // A partial match is only safe for a unique specific name.
        let matches = candidates.filter {
            let key = Self.normalize($0.name)
            return key.contains(queryKey) || queryKey.contains(key)
        }

        return matches.count == 1 ? matches[0] : nil
    }

    func load(scope: ARETDiscoveryScope) async -> ARETPeakLookup {
        var peaks: [ARETPeak] = []
        var failures: [ARETPilotRegion] = []
        var cachedCount = 0

        for region in scope.regions {
            if let entry = cache[region],
               Date().timeIntervalSince(entry.retrievedAt) < cacheLifetime {
                peaks.append(contentsOf: entry.peaks)
                cachedCount += 1
                continue
            }

            do {
                let result = try await load(region: region)
                peaks.append(contentsOf: result)
            } catch {
                failures.append(region)
                // Stale peaks are better than no search, but mark as stale.
                peaks.append(contentsOf: cache[region]?.peaks ?? [])
            }
        }

        let deduplicated = Dictionary(
            grouping: peaks,
            by: \.id
        ).compactMap { $0.value.first }

        return ARETPeakLookup(
            peaks: deduplicated.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            },
            failedRegions: failures,
            isFromCache: cachedCount == scope.regions.count
        )
    }

    private func load(region: ARETPilotRegion) async throws -> [ARETPeak] {
        if let task = ongoing[region] {
            return try await task.value
        }

        let task = Task<[ARETPeak], Error> {
            try await fetch(region: region)
        }
        ongoing[region] = task
        defer { ongoing[region] = nil }

        let peaks = try await task.value
        cache[region] = CacheEntry(
            retrievedAt: Date(),
            peaks: peaks
        )
        return peaks
    }

    private func fetch(region: ARETPilotRegion) async throws -> [ARETPeak] {
        let query = """
        [out:json][timeout:35];
        node["natural"="peak"]["name"](\(region.overpassBoundingBox));
        out body;
        """

        guard let url = URL(
            string: "https://overpass-api.de/api/interpreter"
        ) else {
            throw URLError(.badURL)
        }

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "data", value: query)
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue(
            "ARET-Hiking/0.2 (summit discovery; github.com/lorenzopieri99/Aret)",
            forHTTPHeaderField: "User-Agent"
        )
        request.httpBody = components.percentEncodedQuery?
            .data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard
            let http = response as? HTTPURLResponse,
            (200..<300).contains(http.statusCode)
        else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(OSMResponse.self, from: data)

        return decoded.elements.compactMap { node -> ARETPeak? in
            guard
                node.type == "node",
                let latitude = node.lat,
                let longitude = node.lon,
                let tags = node.tags,
                let name = tags["name:it"] ?? tags["name"],
                !name.trimmingCharacters(in: .whitespaces).isEmpty,
                region.contains(
                    CLLocationCoordinate2D(
                        latitude: latitude,
                        longitude: longitude
                    )
                )
            else {
                return nil
            }

            let elevation = tags["ele"]
                .flatMap {
                    Double(
                        $0.replacingOccurrences(of: ",", with: ".")
                    )
                }

            return ARETPeak(
                id: String(node.id),
                name: name,
                region: region,
                latitude: latitude,
                longitude: longitude,
                elevationMeters: elevation
            )
        }
    }

    private static func normalize(_ text: String) -> String {
        text.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "it_IT")
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private struct OSMResponse: Decodable {
        let elements: [OSMNode]
    }

    private struct OSMNode: Decodable {
        let type: String
        let id: Int64
        let lat: Double?
        let lon: Double?
        let tags: [String: String]?
    }
}
