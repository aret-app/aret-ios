import Foundation
import CoreLocation

struct TerrainElevationProfile: Sendable {
    let coordinates: [ARETCoordinate]
    let ascentMeters: Double
    let descentMeters: Double
    let minimumAltitudeMeters: Double
    let maximumAltitudeMeters: Double
    let sampledPointCount: Int
    let sourceName: String
}

actor TerrainElevationService {
    static let shared = TerrainElevationService()

    private let maximumSamples = 200
    private let minimumSampleSpacingMeters = 80.0
    private let elevationHysteresisMeters = 5.0

    func profile(
        coordinates: [ARETCoordinate]
    ) async throws -> TerrainElevationProfile {
        guard coordinates.count > 1 else {
            throw TerrainElevationError.insufficientGeometry
        }

        let sampledIndices = sampleIndices(
            coordinates: coordinates
        )

        let sampledCoordinates = sampledIndices.map {
            coordinates[$0]
        }

        var sampledElevations: [Double] = []
        sampledElevations.reserveCapacity(
            sampledCoordinates.count
        )

        for batchStart in stride(
            from: 0,
            to: sampledCoordinates.count,
            by: 100
        ) {
            let batchEnd = min(
                batchStart + 100,
                sampledCoordinates.count
            )

            let batch = Array(
                sampledCoordinates[batchStart..<batchEnd]
            )

            let elevations = try await fetchElevations(
                for: batch
            )

            guard elevations.count == batch.count else {
                throw TerrainElevationError.invalidResponse
            }

            sampledElevations.append(
                contentsOf: elevations
            )
        }

        guard
            sampledElevations.count ==
                sampledIndices.count,
            let minimum =
                sampledElevations.min(),
            let maximum =
                sampledElevations.max()
        else {
            throw TerrainElevationError.invalidResponse
        }

        let enriched = interpolateElevations(
            coordinates: coordinates,
            sampledIndices: sampledIndices,
            sampledElevations: sampledElevations
        )

        let vertical = verticalStats(
            elevations: sampledElevations
        )

        return TerrainElevationProfile(
            coordinates: enriched,
            ascentMeters: vertical.ascent,
            descentMeters: vertical.descent,
            minimumAltitudeMeters: minimum,
            maximumAltitudeMeters: maximum,
            sampledPointCount: sampledIndices.count,
            sourceName:
                "Copernicus DEM GLO-90 · Open-Meteo"
        )
    }

    private func fetchElevations(
        for coordinates: [ARETCoordinate]
    ) async throws -> [Double] {
        var components = URLComponents(
            string:
                "https://api.open-meteo.com/v1/elevation"
        )!

        components.queryItems = [
            URLQueryItem(
                name: "latitude",
                value: coordinates
                    .map {
                        String(
                            format: "%.6f",
                            $0.latitude
                        )
                    }
                    .joined(separator: ",")
            ),
            URLQueryItem(
                name: "longitude",
                value: coordinates
                    .map {
                        String(
                            format: "%.6f",
                            $0.longitude
                        )
                    }
                    .joined(separator: ",")
            )
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) =
            try await URLSession.shared.data(
                from: url
            )

        guard
            let http =
                response as? HTTPURLResponse,
            200..<300 ~= http.statusCode
        else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder()
            .decode(
                ElevationResponse.self,
                from: data
            )

        return decoded.elevation
    }

    private func sampleIndices(
        coordinates: [ARETCoordinate]
    ) -> [Int] {
        guard coordinates.count > 2 else {
            return Array(coordinates.indices)
        }

        let totalDistance =
            routeDistance(coordinates)

        let spacing = max(
            minimumSampleSpacingMeters,
            totalDistance /
                Double(maximumSamples - 1)
        )

        var indices: [Int] = [0]
        var accumulated = 0.0
        var lastSampleDistance = 0.0

        for index in 1..<coordinates.count {
            let previous = coordinates[index - 1]
            let current = coordinates[index]

            accumulated += distance(
                from: previous,
                to: current
            )

            if accumulated -
                lastSampleDistance >= spacing {
                indices.append(index)
                lastSampleDistance = accumulated

                if indices.count ==
                    maximumSamples - 1 {
                    break
                }
            }
        }

        if indices.last != coordinates.count - 1 {
            indices.append(
                coordinates.count - 1
            )
        }

        return indices
    }

    private func interpolateElevations(
        coordinates: [ARETCoordinate],
        sampledIndices: [Int],
        sampledElevations: [Double]
    ) -> [ARETCoordinate] {
        guard sampledIndices.count >= 2 else {
            return coordinates
        }

        var result = coordinates

        for samplePosition in
            0..<(sampledIndices.count - 1) {
            let startIndex =
                sampledIndices[samplePosition]
            let endIndex =
                sampledIndices[samplePosition + 1]

            let startElevation =
                sampledElevations[samplePosition]
            let endElevation =
                sampledElevations[
                    samplePosition + 1
                ]

            let denominator =
                max(endIndex - startIndex, 1)

            for index in startIndex...endIndex {
                let fraction =
                    Double(index - startIndex) /
                    Double(denominator)

                let elevation =
                    startElevation +
                    (
                        endElevation -
                        startElevation
                    ) * fraction

                result[index] = ARETCoordinate(
                    latitude:
                        coordinates[index].latitude,
                    longitude:
                        coordinates[index].longitude,
                    altitude: elevation
                )
            }
        }

        return result
    }

    private func verticalStats(
        elevations: [Double]
    ) -> (
        ascent: Double,
        descent: Double
    ) {
        guard
            let first = elevations.first
        else {
            return (0, 0)
        }

        var ascent = 0.0
        var descent = 0.0
        var reference = first

        for elevation in elevations.dropFirst() {
            let delta = elevation - reference

            if abs(delta) >=
                elevationHysteresisMeters {
                if delta > 0 {
                    ascent += delta
                } else {
                    descent += abs(delta)
                }

                reference = elevation
            }
        }

        return (ascent, descent)
    }

    private func routeDistance(
        _ coordinates: [ARETCoordinate]
    ) -> CLLocationDistance {
        var total = 0.0

        for (first, second) in zip(
            coordinates,
            coordinates.dropFirst()
        ) {
            total += distance(
                from: first,
                to: second
            )
        }

        return total
    }

    private func distance(
        from first: ARETCoordinate,
        to second: ARETCoordinate
    ) -> CLLocationDistance {
        CLLocation(
            latitude: first.latitude,
            longitude: first.longitude
        )
        .distance(
            from: CLLocation(
                latitude: second.latitude,
                longitude: second.longitude
            )
        )
    }
}

private struct ElevationResponse:
    Decodable {
    let elevation: [Double]
}

private enum TerrainElevationError:
    LocalizedError {
    case insufficientGeometry
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .insufficientGeometry:
            return
                "Il percorso non contiene abbastanza punti per calcolare il profilo altimetrico."
        case .invalidResponse:
            return
                "Il servizio altimetrico ha restituito dati incompleti."
        }
    }
}
