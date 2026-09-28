import Foundation
import ActivityKit

@MainActor
final class TrackingLiveActivityController {
    static let shared = TrackingLiveActivityController()

    private var activity: Activity<ARETTrackingAttributes>?
    private var lastUpdateAt: Date?

    private init() {}

    func start(
        name: String,
        startedAt: Date
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let initialState =
            ARETTrackingAttributes.ContentState(
                distanceMeters: 0,
                ascentMeters: 0,
                altitudeMeters: nil,
                isTracking: true
            )

        let attributes = ARETTrackingAttributes(
            activityName: name,
            startedAt: startedAt
        )

        Task {
            for existing in Activity<ARETTrackingAttributes>.activities {
                await existing.end(
                    ActivityContent(
                        state: ARETTrackingAttributes.ContentState(
                            distanceMeters: 0,
                            ascentMeters: 0,
                            altitudeMeters: nil,
                            isTracking: false
                        ),
                        staleDate: nil
                    ),
                    dismissalPolicy: .immediate
                )
            }

            do {
                activity = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(
                        state: initialState,
                        staleDate: nil
                    ),
                    pushType: nil
                )
                lastUpdateAt = nil
            } catch {
                print(
                    "ARET Live Activity start error:",
                    error.localizedDescription
                )
            }
        }
    }

    func update(
        distanceMeters: Double,
        ascentMeters: Double,
        altitudeMeters: Double?
    ) {
        guard let activity else { return }

        let now = Date()

        if let lastUpdateAt,
           now.timeIntervalSince(lastUpdateAt) < 5 {
            return
        }

        self.lastUpdateAt = now

        let state =
            ARETTrackingAttributes.ContentState(
                distanceMeters: distanceMeters,
                ascentMeters: ascentMeters,
                altitudeMeters: altitudeMeters,
                isTracking: true
            )

        Task {
            await activity.update(
                ActivityContent(
                    state: state,
                    staleDate:
                        now.addingTimeInterval(90)
                )
            )
        }
    }

    func end(
        distanceMeters: Double,
        ascentMeters: Double,
        altitudeMeters: Double?
    ) {
        guard let activity else { return }

        let state =
            ARETTrackingAttributes.ContentState(
                distanceMeters: distanceMeters,
                ascentMeters: ascentMeters,
                altitudeMeters: altitudeMeters,
                isTracking: false
            )

        Task {
            await activity.end(
                ActivityContent(
                    state: state,
                    staleDate: nil
                ),
                dismissalPolicy: .after(
                    Date().addingTimeInterval(60)
                )
            )
        }

        self.activity = nil
        lastUpdateAt = nil
    }
}
