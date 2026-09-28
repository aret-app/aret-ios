import SwiftUI
import UniformTypeIdentifiers

struct RoutesView: View {
    @EnvironmentObject private var routeLibrary: RouteLibraryStore

    let onSelectRoute: (RouteLibraryItem) -> Void

    @State private var showGPXImporter = false
    @State private var importedRouteName: String?
    @State private var importError: String?

    private var gpxType: UTType {
        UTType(filenameExtension: "gpx") ?? .xml
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Pianifica") {
                    NavigationLink {
                        RoutePlannerSearchView()
                    } label: {
                        Label(
                            "Cerca e pianifica percorso",
                            systemImage: "calendar.badge.clock"
                        )
                    }

                    Text(
                        "Cerca nella libreria ARET o online tra i percorsi hiking aperti, poi scegli il giorno e consulta meteo e finestra favorevole."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        showGPXImporter = true
                    } label: {
                        Label(
                            "Importa traccia GPX",
                            systemImage: "square.and.arrow.down"
                        )
                    }

                    Text(
                        "Il file viene salvato nei tuoi percorsi. Non viene mostrato sulla mappa finché non lo selezioni."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                } header: {
                    Text("Importa")
                }

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
                            "Qui troverai i GPX importati e le attività che scegli di salvare come percorso."
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
        .fileImporter(
            isPresented: $showGPXImporter,
            allowedContentTypes: [gpxType],
            allowsMultipleSelection: false
        ) { result in
            importGPX(result)
        }
        .alert(
            "GPX importato",
            isPresented: Binding(
                get: { importedRouteName != nil },
                set: { if !$0 { importedRouteName = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "\(importedRouteName ?? "Percorso") è stato salvato in I miei percorsi."
            )
        }
        .alert(
            "Importazione non riuscita",
            isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "Errore sconosciuto.")
        }
    }

    private func importGPX(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }

            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let coordinates = try GPXParser().parse(data: data)
            let routeName = url.deletingPathExtension().lastPathComponent

            guard routeLibrary.saveImportedGPX(
                name: routeName,
                coordinates: coordinates
            ) != nil else {
                throw GPXParserError.emptyTrack
            }

            importedRouteName = routeName
        } catch {
            importError = error.localizedDescription
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
