import Foundation
import HealthKit
import Combine

@MainActor
final class WorkoutMirrorManager:
    NSObject,
    ObservableObject {

    @Published private(set)
    var isWatchWorkoutActive = false

    @Published private(set)
    var sessionState:
        HKWorkoutSessionState =
        .notStarted

    @Published private(set)
    var watchActivityName =
        "Attività Apple Watch"

    private let healthStore =
        HKHealthStore()

    private var mirroredSession:
        HKWorkoutSession?

    override init() {
        super.init()

        healthStore
            .workoutSessionMirroringStartHandler = {
                [weak self] session in

                Task { @MainActor in
                    self?.attach(session)
                }
            }
    }

    private func attach(
        _ session: HKWorkoutSession
    ) {
        mirroredSession = session
        session.delegate = self
        sessionState = session.state

        watchActivityName =
            displayName(
                for:
                    session
                        .workoutConfiguration
                        .activityType
            )

        isWatchWorkoutActive =
            session.state == .running
    }

    private func displayName(
        for type: HKWorkoutActivityType
    ) -> String {
        switch type {
        case .hiking:
            return "Escursione · Apple Watch"
        case .climbing:
            return "Arrampicata · Apple Watch"
        default:
            return "Attività · Apple Watch"
        }
    }
}

extension WorkoutMirrorManager:
    HKWorkoutSessionDelegate {

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState:
            HKWorkoutSessionState,
        from fromState:
            HKWorkoutSessionState,
        date: Date
    ) {
        let activityType =
            workoutSession
                .workoutConfiguration
                .activityType

        Task { @MainActor [weak self] in
            guard let self else { return }

            sessionState = toState
            watchActivityName =
                displayName(
                    for: activityType
                )
            isWatchWorkoutActive =
                toState == .running
        }
    }

    nonisolated func workoutSession(
        _ workoutSession:
            HKWorkoutSession,
        didFailWithError error: Error
    ) {
        print(
            "ARET mirrored workout error:",
            error.localizedDescription
        )
    }
}
