import SwiftUI

struct WatchWorkoutView: View {
    @EnvironmentObject private var workoutManager:
        WatchWorkoutManager

    @State private var errorMessage: String?

    var body: some View {
        if workoutManager.isRunning {
            activeWorkout
        } else {
            activityChooser
        }
    }

    private var activityChooser: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(
                    systemName: "mountain.2.fill"
                )
                .font(.title)
                .foregroundStyle(.orange)

                VStack(spacing: 1) {
                    Text("ARET")
                        .font(.headline.bold())

                    Text("Every line. One map.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }

                ForEach(
                    ARETWatchActivityMode.allCases
                ) { mode in
                    Button {
                        start(mode)
                    } label: {
                        HStack(spacing: 8) {
                            Image(
                                systemName:
                                    mode.icon
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
                                    "chevron.right"
                            )
                            .font(.caption2)
                            .foregroundStyle(
                                .secondary
                            )
                        }
                        .frame(
                            maxWidth: .infinity
                        )
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var activeWorkout: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(.orange)
                            .frame(
                                width: 7,
                                height: 7
                            )

                        Text("ARET")
                            .font(
                                .caption
                                .weight(.bold)
                            )
                            .foregroundStyle(
                                .orange
                            )
                    }

                    Spacer()

                    Text(
                        workoutManager
                            .currentMode?
                            .rawValue ??
                        "Attività"
                    )
                    .font(.caption2)
                    .foregroundStyle(
                        .secondary
                    )
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

    private func metric(
        icon: String,
        value: String,
        unit: String,
        title: String,
        accent: Color = .orange
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
            .thinMaterial,
            in: RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
        )
    }

    private func start(
        _ mode: ARETWatchActivityMode
    ) {
        Task {
            do {
                try await workoutManager
                    .requestAuthorization()
                try workoutManager.start(mode)
                errorMessage = nil
            } catch {
                errorMessage =
                    error.localizedDescription
            }
        }
    }
}
