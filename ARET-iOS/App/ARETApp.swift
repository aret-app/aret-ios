import SwiftUI

@main
struct ARETApp: App {
    @StateObject private var locationManager =
        LocationManager()

    @StateObject private var workoutMirrorManager =
        WorkoutMirrorManager()

    @StateObject private var activityStore =
        ActivityStore()

    @StateObject private var routeLibrary =
        RouteLibraryStore()

    @StateObject private var watchRouteSyncManager =
        WatchRouteSyncManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(
                    locationManager
                )
                .environmentObject(
                    workoutMirrorManager
                )
                .environmentObject(
                    activityStore
                )
                .environmentObject(
                    routeLibrary
                )
                .environmentObject(
                    watchRouteSyncManager
                )
                .preferredColorScheme(
                    .dark
                )
        }
    }
}
