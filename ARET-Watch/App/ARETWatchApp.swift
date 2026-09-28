import SwiftUI

@main
struct ARETWatchApp: App {
    @StateObject private var workoutManager =
        WatchWorkoutManager()

    @StateObject private var routeSyncManager =
        WatchRouteSyncManager()

    var body: some Scene {
        WindowGroup {
            WatchWorkoutView()
                .environmentObject(
                    workoutManager
                )
                .environmentObject(
                    routeSyncManager
                )
        }
    }
}
