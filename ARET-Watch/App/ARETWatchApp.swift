import SwiftUI

@main
struct ARETWatchApp: App {
    @StateObject private var workoutManager = WatchWorkoutManager()

    var body: some Scene {
        WindowGroup {
            WatchWorkoutView()
                .environmentObject(workoutManager)
        }
    }
}
