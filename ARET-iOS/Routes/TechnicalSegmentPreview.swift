import SwiftUI
import MapKit

/// Standalone OSM ways are *not* complete summit routes.
/// Show the actual mapped segment, but no navigation/GPX export action.
struct TechnicalSegmentPreview: View {
    let segment: OSMTechnicalSegment

    @State private var camera: MapCameraPosition = .automatic

    private var coordinates: [CLLocationCoordinate2D] {
        segment.points.map(\.clLocationCoordinate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "figure.climbing")
                    .font(.title3)
                    .foregroundStyle(.aretOrange)

                VStack(alignment: .leading, spacing: 3) {
                    Text(segment.name)
                        .font(.headline)

                    Text(segment.difficulty)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("OSM")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.aretOrange)
            }

            if coordinates.count >= 2 {
                Map(position: $camera) {
                    MapPolyline(coordinates: coordinates)
                        .stroke(.aretOrange, lineWidth: 5)

                    if let start = coordinates.first {
                        Marker(
                            "Tratto mappato",
                            systemImage: "point.topleft.down.to.point.bottomright.curvepath",
                            coordinate: start
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
                .frame(height: 170)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                )
                .onAppear(perform: fitSegment)
            }

            Label(
                "SOLO un tratto attrezzato mappato: non è una via completa. Avvicinamento, uscita, difficoltà e discesa NON sono verificati.",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.caption)
            .foregroundStyle(.orange)
            .fixedSize(horizontal: false, vertical: true)

            Link(destination: segment.sourceURL) {
                Label(
                    "Apri il dato originale OpenStreetMap",
                    systemImage: "arrow.up.right.square"
                )
                .font(.caption.weight(.semibold))
            }
            .tint(.aretOrange)
        }
        .aretGlassCard(cornerRadius: 22, padding: 15)
    }

    private func fitSegment() {
        guard coordinates.count >= 2 else { return }

        let points = coordinates.map(MKMapPoint.init)
        guard
            let minX = points.map(\.x).min(),
            let maxX = points.map(\.x).max(),
            let minY = points.map(\.y).min(),
            let maxY = points.map(\.y).max()
        else { return }

        let width = max(40, maxX - minX)
        let height = max(40, maxY - minY)
        let rect = MKMapRect(
            x: minX,
            y: minY,
            width: width,
            height: height
        )
        camera = .rect(
            rect.insetBy(
                dx: -max(width * 0.3, 100),
                dy: -max(height * 0.3, 100)
            )
        )
    }
}
