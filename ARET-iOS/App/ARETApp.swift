import SwiftUI

@main
struct ARETApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var workoutMirrorManager = WorkoutMirrorManager()

    var body: some Scene {
        WindowGroup {
            ExploreView()
                .environmentObject(locationManager)
                .environmentObject(workoutMirrorManager)
                .preferredColorScheme(.dark)
        }
    }
}
