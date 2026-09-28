import SwiftUI

private enum ARETTab: Hashable {
    case map
    case routes
    case activities
    case weather
}

struct MainTabView: View {
    @EnvironmentObject private var routeLibrary: RouteLibraryStore

    @State private var selectedTab: ARETTab = .map

    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreView()
                .tabItem {
                    Label("Mappa", systemImage: "map.fill")
                }
                .tag(ARETTab.map)

            RoutesView { route in
                routeLibrary.select(route)
                selectedTab = .map
            }
            .tabItem {
                Label(
                    "Percorsi",
                    systemImage: "point.topleft.down.to.point.bottomright.curvepath"
                )
            }
            .tag(ARETTab.routes)

            ActivitiesView { route in
                routeLibrary.select(route)
                selectedTab = .map
            }
            .tabItem {
                Label("Attività", systemImage: "figure.hiking")
            }
            .tag(ARETTab.activities)

            WeatherView()
                .tabItem {
                    Label("Meteo", systemImage: "cloud.sun.fill")
                }
                .tag(ARETTab.weather)
        }
        .tint(.orange)
    }
}
