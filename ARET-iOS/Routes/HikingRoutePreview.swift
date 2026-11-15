import SwiftUI
import MapKit
import Charts
import CoreLocation

/// Hiking-first preview. Uses the selected route's actual geometry, never a
/// generated or approximate thumbnail. Elevation is shown only if supplied.
struct HikingRoutePreview: View {
    let route: RouteLibraryItem

    @State private var camera: MapCameraPosition = .automatic

    private struct ElevationPoint: Identifiable {
        let id: Int
        let distanceKilometers: Double
        let altitudeMeters: Double
    }

    private var elevationPoints: [ElevationPoint] {
        guard route.coordinates.count > 1 else { return [] }

        var points: [ElevationPoint] = []
        var distanceMeters = 0.0
        var previous: ARETCoordinate?

        for (index, coordinate) in route.coordinates.enumerated() {
            if let previous {
                let from = CLLocation(
                    latitude: previous.latitude,
                    longitude: previous.longitude
                )
                let to = CLLocation(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                distanceMeters += from.distance(from: to)
            }

            if let altitude = coordinate.altitude, altitude.isFinite {
                points.append(
                    ElevationPoint(
                        id: index,
                        distanceKilometers: distanceMeters / 1000,
                        altitudeMeters: altitude
                    )
                )
            }

            previous = coordinate
        }

        // A cap keeps Swift Charts responsive even for imported dense GPX.
        guard points.count > 240 else { return points }

        let lastIndex = points.count - 1
        return (0..<240).map { slot in
            let sourceIndex = Int(
                (Double(slot) * Double(lastIndex) / 239)
                    .rounded()
            )
            return points[sourceIndex]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label(
                    "ANTEPRIMA TRACCIA",
                    systemImage: "map.fill"
                )
                .font(.caption.weight(.bold))
                .tracking(0.9)

                Spacer()

                Text("DATI REALI")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.aretOrange)
            }

            if route.coordinates.count > 1 {
                Map(position: $camera) {
                    MapPolyline(
                        coordinates: route.coordinates.map(
                            \.clLocationCoordinate
                        )
                    )
                    .stroke(.black.opacity(0.80), lineWidth: 9)

                    MapPolyline(
                        coordinates: route.coordinates.map(
                            \.clLocationCoordinate
                        )
                    )
                    .stroke(.aretOrange, lineWidth: 5)

                    if let first = route.coordinates.first {
                        Marker(
                            "Partenza",
                            systemImage: "figure.hiking",
                            coordinate: first.clLocationCoordinate
                        )
                        .tint(.green)
                    }

                    if let last = route.coordinates.last {
                        Marker(
                            "Arrivo",
                            systemImage: "flag.checkered",
                            coordinate: last.clLocationCoordinate
                        )
                        .tint(.aretOrange)
                    }
                }
                .mapStyle(
                    .standard(
                        elevation: .realistic,
                        emphasis: .muted,
                        pointsOfInterest: .all,
                        showsTraffic: false
                    )
                )
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .frame(height: 225)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                )
                .onAppear(perform: fitRoute)
                .onChange(of: route.id) { _, _ in fitRoute() }
            } else {
                Label(
                    "Traccia GPS non disponibile per questo percorso.",
                    systemImage: "map"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            if elevationPoints.count > 1 {
                elevationProfile(points: elevationPoints)
            } else {
                Label(
                    "Profilo altimetrico non disponibile: servono quote GPS o DEM.",
                    systemImage: "mountain.2"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Text(
                "La linea è una traccia di riferimento, non una conferma che il sentiero sia percorribile. Le quote DEM sono stime e possono essere imprecise sul terreno ripido."
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .aretGlassCard(cornerRadius: 24, padding: 15)
    }

    private func elevationProfile(points: [ElevationPoint]) -> some View {
        let minAltitude = points.map(\.altitudeMeters).min() ?? 0
        let maxAltitude = points.map(\.altitudeMeters).max() ?? 0
        let lowerBound = floor(minAltitude / 20) * 20 - 20
        let upperBound = max(ceil(maxAltitude / 20) * 20 + 20, lowerBound + 50)

        return VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label(
                    "PROFILO ALTIMETRICO",
                    systemImage: "mountain.2.fill"
                )
                .font(.caption.weight(.bold))
                .tracking(0.8)

                Spacer()

                Text(
                    "\(Int(minAltitude.rounded()))–\(Int(maxAltitude.rounded())) m"
                )
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.aretOrange)
            }

            Chart(points) { point in
                AreaMark(
                    x: .value("Distanza", point.distanceKilometers),
                    yStart: .value("Base", lowerBound),
                    yEnd: .value("Quota", point.altitudeMeters)
                )
                .foregroundStyle(.aretOrange.opacity(0.15))

                LineMark(
                    x: .value("Distanza", point.distanceKilometers),
                    y: .value("Quota", point.altitudeMeters)
                )
                .interpolationMethod(.linear)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .foregroundStyle(.aretOrange)
            }
            .chartYScale(domain: lowerBound...upperBound)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3))
            }
            .frame(height: 145)

            HStack {
                Text("Distanza · km")
                Spacer()
                Text("Quota · m")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private func fitRoute() {
        let coordinates = route.coordinates.map(\.clLocationCoordinate)
        guard coordinates.count > 1 else { return }

        let points = coordinates.map(MKMapPoint.init)
        let minX = points.map(\.x).min() ?? 0
        let maxX = points.map(\.x).max() ?? 0
        let minY = points.map(\.y).min() ?? 0
        let maxY = points.map(\.y).max() ?? 0

        let width = max(maxX - minX, 100)
        let height = max(maxY - minY, 100)

        let rect = MKMapRect(
            x: minX,
            y: minY,
            width: width,
            height: height
        )
        camera = .rect(
            rect.insetBy(
                dx: -max(width * 0.18, 180),
                dy: -max(height * 0.18, 180)
            )
        )
    }
}
