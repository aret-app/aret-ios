import Foundation
import WatchConnectivity

@MainActor
final class WatchRouteSyncManager:
    NSObject,
    ObservableObject,
    WCSessionDelegate {

    private let session: WCSession?

    override init() {
        if WCSession.isSupported() {
            session = WCSession.default
        } else {
            session = nil
        }

        super.init()

        session?.delegate = self
        session?.activate()
    }

    func send(
        route: RouteLibraryItem?
    ) {
        guard let session else { return }

        do {
            guard let route else {
                try session.updateApplicationContext(
                    ["hasRoute": false]
                )
                return
            }

            let sampled = sample(
                route.coordinates,
                maximumCount: 140
            )

            let payload: [[String: Double]] =
                sampled.map { coordinate in
                    var item: [String: Double] = [
                        "lat": coordinate.latitude,
                        "lon": coordinate.longitude
                    ]

                    if let altitude =
                        coordinate.altitude {
                        item["alt"] = altitude
                    }

                    return item
                }

            try session.updateApplicationContext(
                [
                    "hasRoute": true,
                    "routeID": route.id,
                    "routeName": route.name,
                    "distanceKM":
                        route.distanceKilometers,
                    "ascentM":
                        route.ascentMeters,
                    "coordinates": payload
                ]
            )
        } catch {
            print(
                "ARET Watch route sync error:",
                error.localizedDescription
            )
        }
    }

    private func sample(
        _ coordinates: [ARETCoordinate],
        maximumCount: Int
    ) -> [ARETCoordinate] {
        guard
            coordinates.count > maximumCount,
            maximumCount > 2
        else {
            return coordinates
        }

        let step =
            Double(coordinates.count - 1) /
            Double(maximumCount - 1)

        var result: [ARETCoordinate] = []
        result.reserveCapacity(maximumCount)

        for index in 0..<maximumCount {
            let sourceIndex = min(
                coordinates.count - 1,
                Int(
                    (
                        Double(index) *
                        step
                    ).rounded()
                )
            )

            result.append(
                coordinates[sourceIndex]
            )
        }

        return result
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith
            activationState:
                WCSessionActivationState,
        error: Error?
    ) {}

    nonisolated func sessionDidBecomeInactive(
        _ session: WCSession
    ) {}

    nonisolated func sessionDidDeactivate(
        _ session: WCSession
    ) {
        session.activate()
    }
}
