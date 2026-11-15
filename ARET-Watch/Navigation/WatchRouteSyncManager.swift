import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchRouteSyncManager:
    NSObject,
    ObservableObject,
    WCSessionDelegate {

    @Published private(set)
    var routeName: String?

    @Published private(set)
    var routeID: String?

    @Published private(set)
    var coordinates: [ARETCoordinate] = []

    @Published private(set)
    var distanceKilometers: Double = 0

    @Published private(set)
    var ascentMeters: Int = 0

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

        if let context =
            session?.receivedApplicationContext,
           !context.isEmpty {
            apply(context)
        }
    }

    private func apply(
        _ context: [String: Any]
    ) {
        guard
            context["hasRoute"] as? Bool ==
                true
        else {
            routeName = nil
            routeID = nil
            coordinates = []
            distanceKilometers = 0
            ascentMeters = 0
            return
        }

        routeName =
            context["routeName"] as? String

        routeID =
            context["routeID"] as? String

        distanceKilometers =
            context["distanceKM"] as? Double ??
            0

        ascentMeters =
            context["ascentM"] as? Int ??
            0

        guard
            let raw =
                context["coordinates"]
                as? [[String: Double]]
        else {
            coordinates = []
            return
        }

        coordinates = raw.compactMap {
            item in

            guard
                let lat = item["lat"],
                let lon = item["lon"]
            else {
                return nil
            }

            let rawAltitude =
                item["alt"]

            let altitude =
                rawAltitude.flatMap {
                    $0.isFinite
                    ? $0
                    : nil
                }

            return ARETCoordinate(
                latitude: lat,
                longitude: lon,
                altitude: altitude
            )
        }
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith
            activationState:
                WCSessionActivationState,
        error: Error?
    ) {}

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext
            applicationContext:
                [String: Any]
    ) {
        Task { @MainActor [weak self] in
            self?.apply(
                applicationContext
            )
        }
    }
}
