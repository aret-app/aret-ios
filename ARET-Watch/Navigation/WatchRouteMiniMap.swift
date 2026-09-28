import SwiftUI

struct WatchRouteMiniMap: View {
    let coordinates: [ARETCoordinate]
    let latitude: Double?
    let longitude: Double?

    var body: some View {
        Canvas { context, size in
            guard coordinates.count > 1 else {
                return
            }

            let latitudes =
                coordinates.map(.latitude)

            let longitudes =
                coordinates.map(.longitude)

            guard
                let minLat = latitudes.min(),
                let maxLat = latitudes.max(),
                let minLon = longitudes.min(),
                let maxLon = longitudes.max()
            else {
                return
            }

            let latSpan =
                max(maxLat - minLat, 0.000001)

            let lonSpan =
                max(maxLon - minLon, 0.000001)

            let padding = 8.0

            func point(
                latitude: Double,
                longitude: Double
            ) -> CGPoint {
                let x =
                    padding +
                    (
                        (longitude - minLon) /
                        lonSpan
                    ) *
                    max(
                        size.width -
                        padding * 2,
                        1
                    )

                let y =
                    padding +
                    (
                        1 -
                        (
                            (latitude - minLat) /
                            latSpan
                        )
                    ) *
                    max(
                        size.height -
                        padding * 2,
                        1
                    )

                return CGPoint(
                    x: x,
                    y: y
                )
            }

            var routePath = Path()

            for (
                index,
                coordinate
            ) in coordinates.enumerated() {
                let p = point(
                    latitude:
                        coordinate.latitude,
                    longitude:
                        coordinate.longitude
                )

                if index == 0 {
                    routePath.move(
                        to: p
                    )
                } else {
                    routePath.addLine(
                        to: p
                    )
                }
            }

            context.stroke(
                routePath,
                with:
                    .color(
                        .aretOrange
                    ),
                style: StrokeStyle(
                    lineWidth: 3.2,
                    lineCap: .round,
                    lineJoin: .round
                )
            )

            if
                let latitude,
                let longitude {
                let userPoint = point(
                    latitude: latitude,
                    longitude:
                        longitude
                )

                let outer =
                    CGRect(
                        x:
                            userPoint.x - 5,
                        y:
                            userPoint.y - 5,
                        width: 10,
                        height: 10
                    )

                context.fill(
                    Path(
                        ellipseIn: outer
                    ),
                    with:
                        .color(.white)
                )

                let inner =
                    outer.insetBy(
                        dx: 2,
                        dy: 2
                    )

                context.fill(
                    Path(
                        ellipseIn: inner
                    ),
                    with:
                        .color(
                            .aretOrange
                        )
                )
            }
        }
        .frame(height: 82)
        .background(
            Color.white.opacity(0.055),
            in: RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .stroke(
                Color.white.opacity(0.08),
                lineWidth: 0.7
            )
        }
    }
}
