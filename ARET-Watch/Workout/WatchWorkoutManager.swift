import Foundation
import HealthKit
import CoreLocation
import Combine
import WatchKit

enum ARETWatchActivityMode:
    String,
    CaseIterable,
    Identifiable,
    Sendable {
    case hiking = "Escursione"
    case climbing = "Arrampicata"
    case alpine = "Alpinismo"
    case indoor = "Indoor"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .hiking:
            return "figure.hiking"
        case .climbing:
            return "figure.climbing"
        case .alpine:
            return "mountain.2.fill"
        case .indoor:
            return "figure.climbing"
        }
    }

    var activityType: HKWorkoutActivityType {
        switch self {
        case .hiking, .alpine:
            return .hiking
        case .climbing, .indoor:
            return .climbing
        }
    }

    var locationType: HKWorkoutSessionLocationType {
        switch self {
        case .indoor:
            return .indoor
        case .hiking, .climbing, .alpine:
            return .outdoor
        }
    }
}

@MainActor
final class WatchWorkoutManager:
    NSObject,
    ObservableObject {

    @Published private(set) var isRunning = false
    @Published private(set) var currentMode:
        ARETWatchActivityMode?

    @Published private(set) var heartRate: Double = 0
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var distanceMeters: Double = 0
    @Published private(set) var activeEnergyKilocalories: Double = 0

    @Published private(set) var altitudeMeters: Double?
    @Published private(set) var ascentMeters: Double = 0
    @Published private(set) var gpsAccuracyMeters: Double?
    @Published private(set) var latitude: Double?
    @Published private(set) var longitude: Double?

    @Published private(set) var navigationRouteName: String?
    @Published private(set) var distanceToRouteMeters: Double?
    @Published private(set) var remainingRouteMeters: Double?
    @Published private(set) var isOffRoute = false

    private let healthStore = HKHealthStore()
    private let locationManager = CLLocationManager()

    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var timer: Timer?
    private var startedAt: Date?
    private var elevationReference: Double?

    private var navigationCoordinates: [ARETCoordinate] = []
    private var lastOffRouteHapticAt: Date?

    override init() {
        super.init()

        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy =
            kCLLocationAccuracyBest
        locationManager.distanceFilter = 3
        locationManager
            .pausesLocationUpdatesAutomatically = false
    }

    func requestAuthorization() async throws {
        guard
            let heartRate =
                HKQuantityType.quantityType(
                    forIdentifier: .heartRate
                ),
            let activeEnergy =
                HKQuantityType.quantityType(
                    forIdentifier: .activeEnergyBurned
                ),
            let distance =
                HKQuantityType.quantityType(
                    forIdentifier: .distanceWalkingRunning
                )
        else {
            return
        }

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

        try await healthStore.requestAuthorization(
            toShare: share,
            read: read
        )
    }

    func start(
        _ mode: ARETWatchActivityMode
    ) throws {
        guard !isRunning else { return }

        let configuration =
            HKWorkoutConfiguration()
        configuration.activityType =
            mode.activityType
        configuration.locationType =
            mode.locationType

        let session = try HKWorkoutSession(
            healthStore: healthStore,
            configuration: configuration
        )

        let builder =
            session.associatedWorkoutBuilder()

        builder.dataSource =
            HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration:
                    configuration
            )

        session.delegate = self
        builder.delegate = self
        self.session = session
        self.builder = builder

        let start = Date()

        currentMode = mode
        startedAt = start
        elapsedTime = 0
        distanceMeters = 0
        activeEnergyKilocalories = 0
        heartRate = 0
        altitudeMeters = nil
        ascentMeters = 0
        gpsAccuracyMeters = nil
        latitude = nil
        longitude = nil
        elevationReference = nil
        distanceToRouteMeters = nil
        remainingRouteMeters = nil
        isOffRoute = false
        lastOffRouteHapticAt = nil

        if mode.locationType == .outdoor {
            switch locationManager
                .authorizationStatus {
            case .notDetermined:
                locationManager
                    .requestWhenInUseAuthorization()
            case .authorizedAlways,
                 .authorizedWhenInUse:
                locationManager
                    .startUpdatingLocation()
            default:
                break
            }
        }

        session.startActivity(with: start)

        session.startMirroringToCompanionDevice {
            success,
            error in

            if let error {
                print(
                    "ARET workout mirroring error:",
                    error.localizedDescription
                )
            } else if !success {
                print(
                    "ARET workout mirroring did not start."
                )
            }
        }

        builder.beginCollection(
            withStart: start
        ) { _, error in
            if let error {
                print(
                    "ARET begin workout error:",
                    error.localizedDescription
                )
            }
        }

        isRunning = true
        startTimer()
    }

    func stop() {
        session?.end()
    }

    func setNavigationRoute(
        name: String?,
        coordinates: [ARETCoordinate]
    ) {
        navigationRouteName = name
        navigationCoordinates = coordinates

        if coordinates.count < 2 {
            distanceToRouteMeters = nil
            remainingRouteMeters = nil
            isOffRoute = false
        }
    }

    private func startTimer() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                guard
                    let self,
                    let startedAt =
                        self.startedAt
                else {
                    return
                }

                self.elapsedTime =
                    Date().timeIntervalSince(
                        startedAt
                    )
            }
        }
    }

    private func consumeLocation(
        _ location: CLLocation
    ) {
        guard
            location.horizontalAccuracy >= 0,
            location.horizontalAccuracy <= 50
        else {
            return
        }

        altitudeMeters = location.altitude
        gpsAccuracyMeters =
            location.horizontalAccuracy
        latitude =
            location.coordinate.latitude
        longitude =
            location.coordinate.longitude

        updateNavigation(
            for: location
        )

        guard
            location.verticalAccuracy >= 0,
            location.verticalAccuracy <= 50
        else {
            return
        }

        if let reference =
            elevationReference {
            let delta =
                location.altitude -
                reference

            if abs(delta) >= 3 {
                if delta > 0 {
                    ascentMeters += delta
                }

                elevationReference =
                    location.altitude
            }
        } else {
            elevationReference =
                location.altitude
        }
    }

    private func updateNavigation(
        for location: CLLocation
    ) {
        guard
            navigationCoordinates.count >= 2
        else {
            distanceToRouteMeters = nil
            remainingRouteMeters = nil
            isOffRoute = false
            return
        }

        distanceToRouteMeters =
            RouteDistanceCalculator.distance(
                from: location.coordinate,
                to: navigationCoordinates
            )

        var nearestIndex = 0
        var nearestDistance =
            Double.greatestFiniteMagnitude

        for (
            index,
            coordinate
        ) in navigationCoordinates.enumerated() {
            let distance =
                location.distance(
                    from: CLLocation(
                        latitude:
                            coordinate.latitude,
                        longitude:
                            coordinate.longitude
                    )
                )

            if distance < nearestDistance {
                nearestDistance = distance
                nearestIndex = index
            }
        }

        var remaining = 0.0

        if nearestIndex <
            navigationCoordinates.count - 1 {
            for index in nearestIndex..<(navigationCoordinates.count - 1) {
                let first =
                    navigationCoordinates[index]
                let second =
                    navigationCoordinates[index + 1]

                remaining += CLLocation(
                    latitude: first.latitude,
                    longitude: first.longitude
                )
                .distance(
                    from: CLLocation(
                        latitude: second.latitude,
                        longitude: second.longitude
                    )
                )
            }
        }

        remainingRouteMeters = remaining

        let offRoute =
            (distanceToRouteMeters ?? 0) > 75

        if offRoute && !isOffRoute {
            playOffRouteHapticIfNeeded()
        }

        isOffRoute = offRoute
    }

    private func playOffRouteHapticIfNeeded() {
        let now = Date()

        if let lastOffRouteHapticAt,
           now.timeIntervalSince(
               lastOffRouteHapticAt
           ) < 60 {
            return
        }

        lastOffRouteHapticAt = now

        WKInterfaceDevice.current()
            .play(.notification)
    }
}

extension WatchWorkoutManager:
    HKWorkoutSessionDelegate {

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState:
            HKWorkoutSessionState,
        from fromState:
            HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            if toState == .ended {
                timer?.invalidate()
                locationManager
                    .stopUpdatingLocation()

                builder?.endCollection(
                    withEnd: date
                ) { [weak self] _, _ in
                    self?.builder?
                        .finishWorkout {
                            _,
                            error in

                            if let error {
                                print(
                                    "ARET finish workout error:",
                                    error
                                        .localizedDescription
                                )
                            }
                        }
                }

                workoutSession
                    .stopMirroringToCompanionDevice {
                        _,
                        error in

                        if let error {
                            print(
                                "ARET stop mirroring error:",
                                error
                                    .localizedDescription
                            )
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
        print(
            "ARET workout error:",
            error.localizedDescription
        )
    }
}

extension WatchWorkoutManager:
    HKLiveWorkoutBuilderDelegate {

    nonisolated func workoutBuilderDidCollectEvent(
        _ workoutBuilder:
            HKLiveWorkoutBuilder
    ) {}

    nonisolated func workoutBuilder(
        _ workoutBuilder:
            HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes:
            Set<HKSampleType>
    ) {
        if
            let heartRateType =
                HKQuantityType.quantityType(
                    forIdentifier: .heartRate
                ),
            collectedTypes.contains(
                heartRateType
            ),
            let statistics =
                workoutBuilder.statistics(
                    for: heartRateType
                ),
            let quantity =
                statistics.mostRecentQuantity()
        {
            let unit =
                HKUnit.count()
                    .unitDivided(
                        by: .minute()
                    )

            let bpm =
                quantity.doubleValue(
                    for: unit
                )

            Task { @MainActor [weak self] in
                self?.heartRate = bpm
            }
        }

        if
            let distanceType =
                HKQuantityType.quantityType(
                    forIdentifier:
                        .distanceWalkingRunning
                ),
            collectedTypes.contains(
                distanceType
            ),
            let statistics =
                workoutBuilder.statistics(
                    for: distanceType
                ),
            let quantity =
                statistics.sumQuantity()
        {
            let meters =
                quantity.doubleValue(
                    for: .meter()
                )

            Task { @MainActor [weak self] in
                self?.distanceMeters =
                    meters
            }
        }

        if
            let energyType =
                HKQuantityType.quantityType(
                    forIdentifier:
                        .activeEnergyBurned
                ),
            collectedTypes.contains(
                energyType
            ),
            let statistics =
                workoutBuilder.statistics(
                    for: energyType
                ),
            let quantity =
                statistics.sumQuantity()
        {
            let kcal =
                quantity.doubleValue(
                    for: .kilocalorie()
                )

            Task { @MainActor [weak self] in
                self?
                    .activeEnergyKilocalories =
                    kcal
            }
        }
    }
}

extension WatchWorkoutManager:
    CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        let status =
            manager.authorizationStatus

        Task { @MainActor [weak self] in
            guard
                let self,
                isRunning,
                currentMode?.locationType ==
                    .outdoor
            else {
                return
            }

            if status == .authorizedAlways ||
                status ==
                    .authorizedWhenInUse {
                locationManager
                    .startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations:
            [CLLocation]
    ) {
        guard let newest =
            locations.last
        else {
            return
        }

        Task { @MainActor [weak self] in
            self?.consumeLocation(newest)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print(
            "ARET Watch location error:",
            error.localizedDescription
        )
    }
}
