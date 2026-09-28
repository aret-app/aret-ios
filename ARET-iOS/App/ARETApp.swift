import SwiftUI

@main
struct ARETApp: App {
    @StateObject private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ExploreView()
                .environmentObject(locationManager)
                .preferredColorScheme(.dark)
        }
    }
}
