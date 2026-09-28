import SwiftUI

struct WatchWorkoutView: View {
    @EnvironmentObject private var workoutManager: WatchWorkoutManager

    var body: some View {
        VStack(spacing: 9) {
            if workoutManager.isRunning {
                Text("ARET")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)

                Text(Duration.seconds(workoutManager.elapsedTime), format: .time(pattern: .hourMinuteSecond))
                    .font(.title3.monospacedDigit())

                HStack(spacing: 12) {
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                            Text("\(Int(workoutManager.heartRate))")
                                .monospacedDigit()
                        }
                        Text("bpm")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 2) {
                        Text(
                            workoutManager.distanceMeters / 1000,
                            format: .number.precision(.fractionLength(2))
                        )
                        .monospacedDigit()
                        Text("km")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Stop", role: .destructive) {
                    workoutManager.stop()
                }
            } else {
                Image(systemName: "mountain.2.fill")
                    .font(.largeTitle)

                Text("ARET")
                    .font(.title3.bold())

                Text("Every line. One map.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button("Start hike") {
                    Task {
                        do {
                            try await workoutManager.requestAuthorization()
                            try workoutManager.startHike()
                        } catch {
                            print("ARET HealthKit error:", error.localizedDescription)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding()
    }
}
