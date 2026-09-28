import Foundation
import HealthKit
import Combine

@MainActor
final class WatchWorkoutManager: NSObject, ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var heartRate: Double = 0
    @Published private(set) var elapsedTime: TimeInterval = 0

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var timer: Timer?
    private var startedAt: Date?

    func requestAuthorization() async throws {
        guard
            let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate),
            let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
            let distance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        else { return }

        let share: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            activeEnergy,
            distance
        ]

        let read: Set<HKObjectType> = [
            heartRate,
            activeEnergy,
            distance
        ]

        try await healthStore.requestAuthorization(toShare: share, read: read)
    }

    func startHike() throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .hiking
        configuration.locationType = .outdoor

        let session = try HKWorkoutSession(
            healthStore: healthStore,
            configuration: configuration
        )

        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )

        session.delegate = self
        builder.delegate = self
        self.session = session
        self.builder = builder

        let start = Date()
        startedAt = start
        session.startActivity(with: start)
        builder.beginCollection(withStart: start) { _, error in
            if let error {
                print("ARET begin workout error:", error.localizedDescription)
            }
        }

        isRunning = true
        startTimer()
    }

    func stop() {
        session?.end()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startedAt = self.startedAt else { return }
                self.elapsedTime = Date().timeIntervalSince(startedAt)
            }
        }
    }
}

extension WatchWorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in
            if toState == .ended {
                timer?.invalidate()
                builder?.endCollection(withEnd: date) { [weak self] _, _ in
                    self?.builder?.finishWorkout { _, error in
                        if let error {
                            print("ARET finish workout error:", error.localizedDescription)
                        }
                    }
                }
                isRunning = false
            }
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        print("ARET workout error:", error.localizedDescription)
    }
}

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        guard
            let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
            collectedTypes.contains(heartRateType),
            let statistics = workoutBuilder.statistics(for: heartRateType),
            let quantity = statistics.mostRecentQuantity()
        else { return }

        let unit = HKUnit.count().unitDivided(by: .minute())
        let bpm = quantity.doubleValue(for: unit)

        Task { @MainActor in
            heartRate = bpm
        }
    }
}
