import SwiftUI

struct WatchWorkoutView: View {
    @EnvironmentObject private var workoutManager: WatchWorkoutManager

    var body: some View {
        VStack(spacing: 10) {
            if workoutManager.isRunning {
                Text("ARET")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)

                Text(workoutManager.elapsedTime, format: .time(pattern: .hourMinuteSecond))
                    .font(.title3.monospacedDigit())

                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("\(Int(workoutManager.heartRate))")
                        .font(.title2.monospacedDigit())
                    Text("bpm")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
