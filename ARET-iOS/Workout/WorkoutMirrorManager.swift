import Foundation
import HealthKit
import Combine

@MainActor
final class WorkoutMirrorManager: NSObject, ObservableObject {
    @Published private(set) var isWatchWorkoutActive = false
    @Published private(set) var sessionState: HKWorkoutSessionState = .notStarted

    private let healthStore = HKHealthStore()
    private var mirroredSession: HKWorkoutSession?

    override init() {
        super.init()

        healthStore.workoutSessionMirroringStartHandler = { [weak self] session in
            Task { @MainActor in
                self?.attach(session)
            }
        }
    }

    private func attach(_ session: HKWorkoutSession) {
        mirroredSession = session
        session.delegate = self
        sessionState = session.state
        isWatchWorkoutActive = session.state == .running
    }
}

extension WorkoutMirrorManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in
            sessionState = toState
            isWatchWorkoutActive = toState == .running
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        print("ARET mirrored workout error:", error.localizedDescription)
    }
}
