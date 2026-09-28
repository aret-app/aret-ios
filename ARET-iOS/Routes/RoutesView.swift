import SwiftUI

struct RoutesView: View {
    @EnvironmentObject private var routeLibrary: RouteLibraryStore

    let onSelectRoute: (RouteLibraryItem) -> Void

    var body: some View {
        NavigationStack {
            List {
                if let activeRoute = routeLibrary.activeRoute {
                    Section("Percorso attivo") {
                        RouteRow(route: activeRoute, isActive: true) {
                            onSelectRoute(activeRoute)
                        }

                        Button(role: .destructive) {
                            routeLibrary.clearSelection()
                        } label: {
                            Label(
                                "Rimuovi dalla mappa",
                                systemImage: "xmark.circle"
                            )
                        }
                    }
                }

                Section("ARET") {
                    ForEach(routeLibrary.catalogRoutes) { route in
                        RouteRow(
                            route: route,
                            isActive: routeLibrary.activeRoute?.id == route.id
                        ) {
                            routeLibrary.select(route)
                            onSelectRoute(route)
                        }
                    }
                }

                Section("I miei percorsi") {
                    if routeLibrary.personalRoutes.isEmpty {
                        Text(
                            "Quando termini un'attività puoi scegliere di salvarla qui per rifarla."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    } else {
                        ForEach(routeLibrary.personalRoutes) { route in
                            RouteRow(
                                route: route,
                                isActive: routeLibrary.activeRoute?.id == route.id
                            ) {
                                routeLibrary.select(route)
                                onSelectRoute(route)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    routeLibrary.deletePersonalRoute(route)
                                } label: {
                                    Label("Elimina", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Percorsi")
        }
    }
}

private struct RouteRow: View {
    let route: RouteLibraryItem
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(
                    systemName: route.kind == .hiking
                    ? "figure.hiking"
                    : "mountain.2.fill"
                )
                .foregroundStyle(.orange)
                .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(route.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.orange)
                        }
                    }

                    Text(route.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        "\(route.distanceKilometers, specifier: "%.1f") km · +\(route.ascentMeters) m · max \(route.maximumAltitudeMeters) m"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
