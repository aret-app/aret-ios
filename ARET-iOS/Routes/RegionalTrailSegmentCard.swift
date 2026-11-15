import SwiftUI
import MapKit

/// OSM way segment only. It may be part of many routes and should NOT be
/// treated as a complete ascent, automatically exported, or linked to a
/// summit with straight-line connectors.
struct RegionalTrailSegmentCard: View {
    let segment: OSMTrailSegment

    @State private var expanded = false
    @State private var camera: MapCameraPosition = .automatic

    private var coordinates: [CLLocationCoordinate2D] {
        segment.points.map(\.clLocationCoordinate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    expanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 11) {
                    Image(systemName: "figure.hiking")
                        .font(.title3)
                        .foregroundStyle(.aretOrange)
                        .frame(width: 25)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(segment.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        Text(segment.grade)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    Image(
                        systemName: expanded ? "chevron.up" : "chevron.down"
                    )
                    .foregroundStyle(.secondary)
                    .font(.caption.weight(.semibold))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                if coordinates.count >= 2 {
                    Map(position: $camera) {
                        MapPolyline(coordinates: coordinates)
                            .stroke(.aretOrange, lineWidth: 4.5)
                    }
                    .mapStyle(
                        .standard(
                            elevation: .realistic,
                            emphasis: .muted,
                            pointsOfInterest: .all,
                            showsTraffic: false
                        )
                    )
                    .frame(height: 160)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 15)
                    )
                    .onAppear(perform: fitSegment)
                }

                Label(
                    "È soltanto un segmento della rete sentieristica: non è una via completa né una traccia verificata fino alla cima.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)

                Link(destination: segment.sourceURL) {
                    Label(
                        "Mostra fonte OpenStreetMap",
                        systemImage: "arrow.up.right.square"
                    )
                    .font(.caption.weight(.semibold))
                }
                .tint(.aretOrange)
            }
        }
        .aretGlassCard(cornerRadius: 19, padding: 13)
    }

    private func fitSegment() {
        let points = coordinates.map(MKMapPoint.init)
        guard
            let minX = points.map(\.x).min(),
            let maxX = points.map(\.x).max(),
            let minY = points.map(\.y).min(),
            let maxY = points.map(\.y).max()
        else { return }

        let width = max(maxX - minX, 40)
        let height = max(maxY - minY, 40)

        camera = .rect(
            MKMapRect(
                x: minX,
                y: minY,
                width: width,
                height: height
            )
            .insetBy(
                dx: -max(width * 0.25, 100),
                dy: -max(height * 0.25, 100)
            )
        )
    }
}
