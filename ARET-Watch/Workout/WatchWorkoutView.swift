import SwiftUI
import WatchKit

struct WatchWorkoutView: View {
    @EnvironmentObject private var workoutManager:
        WatchWorkoutManager

    @EnvironmentObject private var routeSync:
        WatchRouteSyncManager

    @State private var errorMessage: String?

    var body: some View {
        Group {
            if workoutManager.isRunning {
                activeWorkout
            } else {
                activityChooser
            }
        }
        .background(Color.aretBackground)
        .onAppear {
            syncNavigationRoute()
        }
        .onChange(of: routeSync.routeID) {
            _, _ in
            syncNavigationRoute()
        }
    }

    private var activityChooser: some View {
        ScrollView {
            VStack(spacing: 12) {
                ARETMark(size: 42)

                VStack(spacing: 2) {
                    Text("ARET")
                        .font(.headline.bold())
                        .tracking(4)

                    Text("Every line. One map.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let routeName =
                    routeSync.routeName {
                    HStack(spacing: 6) {
                        Image(
                            systemName:
                                "point.topleft.down.to.point.bottomright.curvepath"
                        )
                        .foregroundStyle(
                            .aretOrange
                        )

                        Text(routeName)
                            .lineLimit(1)
                    }
                    .font(.caption2)
                    .aretGlassCard(
                        cornerRadius: 14,
                        padding: 9
                    )
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }

                ForEach(
                    ARETWatchActivityMode
                        .allCases
                ) { mode in
                    Button {
                        start(mode)
                    } label: {
                        HStack(spacing: 8) {
                            Image(
                                systemName:
                                    mode.icon
                            )
                            .foregroundStyle(
                                .aretOrange
                            )
                            .frame(width: 22)

                            Text(mode.rawValue)
                                .font(
                                    .footnote
                                    .weight(
                                        .semibold
                                    )
                                )

                            Spacer()

                            Image(
                                systemName:
                                    "play.fill"
                            )
                            .font(.caption2)
                        }
                        .padding(.vertical, 3)
                    }
                    .buttonStyle(.bordered)
                    .tint(.aretOrange)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var activeWorkout: some View {
        TabView {
            metricsPage
            navigationPage
            safetyPage
        }
        .tint(.aretOrange)
    }

    private var metricsPage: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    ARETWordmark(compact: true)

                    Spacer()

                    Circle()
                        .fill(.aretOrange)
                        .frame(width: 7, height: 7)
                }

                Text(
                    Duration.seconds(
                        workoutManager
                            .elapsedTime
                    ),
                    format:
                        .time(
                            pattern:
                                .hourMinuteSecond
                        )
                )
                .font(
                    .title2
                    .weight(.semibold)
                    .monospacedDigit()
                )
                .foregroundStyle(
                    .aretOrange
                )

                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 8
                ) {
                    metric(
                        icon: "heart.fill",
                        value:
                            "\(Int(workoutManager.heartRate.rounded()))",
                        unit: "bpm",
                        title: "Battito",
                        accent: .red
                    )

                    metric(
                        icon:
                            "point.topleft.down.to.point.bottomright.curvepath",
                        value: String(
                            format: "%.2f",
                            workoutManager
                                .distanceMeters /
                            1000
                        ),
                        unit: "km",
                        title: "Distanza"
                    )

                    metric(
                        icon: "arrow.up.right",
                        value:
                            "\(Int(workoutManager.ascentMeters.rounded()))",
                        unit: "m",
                        title: "D+"
                    )

                    metric(
                        icon:
                            "mountain.2.fill",
                        value:
                            workoutManager
                                .altitudeMeters
                                .map {
                                    "\(Int($0.rounded()))"
                                } ?? "—",
                        unit: "m",
                        title: "Quota"
                    )
                }

                HStack {
                    Label(
                        "\(Int(workoutManager.activeEnergyKilocalories.rounded())) kcal",
                        systemImage: "flame.fill"
                    )

                    Spacer()

                    if let accuracy =
                        workoutManager
                            .gpsAccuracyMeters {
                        Label(
                            "±\(Int(accuracy.rounded())) m",
                            systemImage:
                                "location.fill"
                        )
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                Button(
                    "Termina",
                    role: .destructive
                ) {
                    workoutManager.stop()
                }
                .frame(
                    maxWidth: .infinity
                )
            }
            .padding(.horizontal, 4)
        }
    }

    private var navigationPage: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Label(
                    "Navigazione",
                    systemImage:
                        "location.north.fill"
                )
                .font(.headline)
                .foregroundStyle(
                    .aretOrange
                )

                if let routeName =
                    workoutManager
                        .navigationRouteName {
                    Text(routeName)
                        .font(
                            .subheadline
                            .weight(.semibold)
                        )
                        .lineLimit(2)

                    if workoutManager.isOffRoute {
                        Label(
                            "FUORI TRACCIA",
                            systemImage:
                                "exclamationmark.triangle.fill"
                        )
                        .font(
                            .caption
                            .weight(.bold)
                        )
                        .foregroundStyle(.orange)
                    } else {
                        Label(
                            "Sulla traccia",
                            systemImage:
                                "checkmark.circle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.green)
                    }

                    navigationMetric(
                        title:
                            "Distanza dalla traccia",
                        meters:
                            workoutManager
                                .distanceToRouteMeters
                    )

                    navigationMetric(
                        title:
                            "Percorso rimanente",
                        meters:
                            workoutManager
                                .remainingRouteMeters
                    )

                    if let accuracy =
                        workoutManager
                            .gpsAccuracyMeters {
                        Text(
                            "GPS ±\(Int(accuracy.rounded())) m"
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                } else {
                    ContentUnavailableView(
                        "Nessun percorso",
                        systemImage: "map",
                        description: Text(
                            "Seleziona un itinerario su iPhone: ARET lo invierà al Watch."
                        )
                    )
                }
            }
            .padding(.horizontal, 6)
        }
    }

    private var safetyPage: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(
                    systemName:
                        "sos.circle.fill"
                )
                .font(.largeTitle)
                .foregroundStyle(.red)

                Text("Emergenza")
                    .font(.headline)

                VStack(spacing: 3) {
                    if
                        let latitude =
                            workoutManager
                                .latitude,
                        let longitude =
                            workoutManager
                                .longitude {
                        Text(
                            String(
                                format:
                                    "%.5f, %.5f",
                                latitude,
                                longitude
                            )
                        )
                        .font(
                            .caption
                            .monospacedDigit()
                        )
                    } else {
                        Text(
                            "Coordinate GPS non ancora disponibili"
                        )
                        .font(.caption)
                    }

                    if let altitude =
                        workoutManager
                            .altitudeMeters {
                        Text(
                            "Quota \(Int(altitude.rounded())) m"
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }

                Button(
                    role: .destructive
                ) {
                    callEmergencyNumber()
                } label: {
                    Label(
                        "Chiama 112",
                        systemImage: "phone.fill"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )
                .tint(.red)

                Text(
                    "La chiamata viene gestita dal sistema e richiede la tua azione."
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 6)
        }
    }

    private func metric(
        icon: String,
        value: String,
        unit: String,
        title: String,
        accent: Color = .aretOrange
    ) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(accent)

            HStack(
                alignment: .firstTextBaseline,
                spacing: 2
            ) {
                Text(value)
                    .font(
                        .headline
                        .monospacedDigit()
                    )

                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(.vertical, 7)
        .background(
            Color.white.opacity(0.055),
            in: RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
        )
    }

    private func navigationMetric(
        title: String,
        meters: Double?
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 3
        ) {
            Text(
                formattedDistance(
                    meters
                )
            )
            .font(
                .title3
                .weight(.semibold)
                .monospacedDigit()
            )

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(10)
        .background(
            Color.white.opacity(0.055),
            in: RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
        )
    }

    private func formattedDistance(
        _ meters: Double?
    ) -> String {
        guard let meters else {
            return "—"
        }

        if meters < 1000 {
            return "\(Int(meters.rounded())) m"
        }

        return String(
            format: "%.1f km",
            meters / 1000
        )
    }

    private func syncNavigationRoute() {
        workoutManager
            .setNavigationRoute(
                name: routeSync.routeName,
                coordinates:
                    routeSync.coordinates
            )
    }

    private func start(
        _ mode: ARETWatchActivityMode
    ) {
        Task {
            do {
                syncNavigationRoute()

                try await workoutManager
                    .requestAuthorization()

                try workoutManager
                    .start(mode)

                errorMessage = nil
            } catch {
                errorMessage =
                    error.localizedDescription
            }
        }
    }

    private func callEmergencyNumber() {
        guard
            let url =
                URL(string: "tel:112")
        else {
            return
        }

        WKApplication.shared()
            .openSystemURL(url)
    }
}
