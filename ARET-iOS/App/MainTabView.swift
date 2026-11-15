import SwiftUI

private enum ARETTab: Hashable {
    case map
    case routes
    case activities
    case weather
    case profile
}

struct MainTabView: View {
    @EnvironmentObject private var routeLibrary:
        RouteLibraryStore

    @EnvironmentObject private var locationManager:
        LocationManager

    @EnvironmentObject private var activityStore:
        ActivityStore

    @EnvironmentObject private var workoutMirrorManager:
        WorkoutMirrorManager

    @EnvironmentObject private var watchRouteSyncManager:
        WatchRouteSyncManager

    @State private var selectedTab:
        ARETTab = .map

    @State private var watchStartedPhoneTracking =
        false

    @State private var watchTrackingName =
        "Attività Apple Watch"

    @State private var watchSourceRouteID:
        String?

    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreView()
                .tabItem {
                    Label(
                        "Esplora",
                        systemImage:
                            "mountain.2.fill"
                    )
                }
                .tag(ARETTab.map)

            RoutesView { route in
                routeLibrary.select(route)
                selectedTab = .map
            }
            .tabItem {
                Label(
                    "Itinerari",
                    systemImage:
                        "point.topleft.down.to.point.bottomright.curvepath"
                )
            }
            .tag(ARETTab.routes)

            ActivitiesView { route in
                routeLibrary.select(route)
                selectedTab = .map
            }
            .tabItem {
                Label(
                    "Attività",
                    systemImage:
                        "figure.hiking"
                )
            }
            .tag(ARETTab.activities)

            WeatherView()
                .tabItem {
                    Label(
                        "Meteo",
                        systemImage:
                            "cloud.sun.fill"
                    )
                }
                .tag(ARETTab.weather)

            PrivacyView()
                .tabItem {
                    Label(
                        "Profilo",
                        systemImage:
                            "person.crop.circle.fill"
                    )
                }
                .tag(ARETTab.profile)
        }
        .safeAreaInset(edge: .top) {
            if locationManager.hasIncompleteRecording && !locationManager.isTracking {
                VStack {
                    Text("Registrazione incompleta disponibile")
                    Button("Recupera e salva i punti") {
                        if let activity = locationManager.recoverRecording() {
                            if activityStore.add(activity) {
                                locationManager.confirmRecordingSaved()
                            } else {
                                locationManager.recordingError = "Salvataggio fallito; punti conservati."
                            }
                        }
                    }
                }
                .padding()
                .background(.regularMaterial)
            }
        }
        .alert("Registrazione GPS", isPresented: Binding(
            get: { locationManager.recordingError != nil },
            set: { if !$0 { locationManager.recordingError = nil } }
        )) {
            Button("OK") { locationManager.recordingError = nil }
        } message: {
            Text(locationManager.recordingError ?? "")
        }
        .tint(.aretOrange)
        .toolbarBackground(
            .visible,
            for: .tabBar
        )
        .toolbarBackground(
            Color.black.opacity(0.94),
            for: .tabBar
        )
        .onAppear {
            watchRouteSyncManager.send(
                route:
                    routeLibrary.activeRoute
            )

            handleWatchWorkoutState(
                workoutMirrorManager
                    .isWatchWorkoutActive
            )
        }
        .onChange(
            of: routeLibrary.activeRoute?.id
        ) { _, _ in
            watchRouteSyncManager.send(
                route:
                    routeLibrary.activeRoute
            )
        }
        .onChange(
            of:
                workoutMirrorManager
                    .isWatchWorkoutActive
        ) { _, active in
            handleWatchWorkoutState(
                active
            )
        }
    }

    private func handleWatchWorkoutState(
        _ active: Bool
    ) {
        if active {
            guard
                !locationManager.isTracking
            else {
                return
            }

            watchTrackingName =
                routeLibrary.activeRoute?.name ??
                workoutMirrorManager
                    .watchActivityName

            watchSourceRouteID =
                routeLibrary.activeRoute?.id

            locationManager
                .requestPermission()

            locationManager
                .startTracking(
                    name: watchTrackingName
                )

            watchStartedPhoneTracking =
                locationManager.isTracking

            selectedTab = .map
            return
        }

        guard
            watchStartedPhoneTracking
        else {
            return
        }

        if locationManager.isTracking,
           let activity =
            locationManager.stopTracking(
                name: watchTrackingName,
                sourceRouteID:
                    watchSourceRouteID
            ) {
            if activityStore.add(activity) {
                locationManager.confirmRecordingSaved()
            } else {
                locationManager.recordingError = "Attività non salvata. Registrazione conservata per il recupero."
            }
        }

        watchStartedPhoneTracking = false
        watchSourceRouteID = nil
    }
}
