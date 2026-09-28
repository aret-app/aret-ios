import SwiftUI
import UniformTypeIdentifiers

struct RoutesView: View {
    @EnvironmentObject private var routeLibrary:
        RouteLibraryStore

    let onSelectRoute:
        (RouteLibraryItem) -> Void

    @State private var showGPXImporter =
        false

    @State private var importedRouteName:
        String?

    @State private var importError:
        String?

    private var gpxType: UTType {
        UTType(
            filenameExtension: "gpx"
        ) ?? .xml
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(
                    alignment: .leading,
                    spacing: 18
                ) {
                    hero

                    if let activeRoute =
                        routeLibrary
                            .activeRoute {
                        sectionTitle(
                            "Percorso attivo"
                        )

                        routeCard(
                            activeRoute,
                            isActive: true,
                            canDelete: false
                        )
                    }

                    sectionTitle("ARET")

                    ForEach(
                        routeLibrary.catalogRoutes
                    ) { route in
                        routeCard(
                            route,
                            isActive:
                                routeLibrary
                                    .activeRoute?
                                    .id ==
                                route.id,
                            canDelete: false
                        )
                    }

                    sectionTitle(
                        "I miei percorsi"
                    )

                    if routeLibrary
                        .personalRoutes
                        .isEmpty {
                        emptyPersonalRoutes
                    } else {
                        ForEach(
                            routeLibrary
                                .personalRoutes
                        ) { route in
                            routeCard(
                                route,
                                isActive:
                                    routeLibrary
                                        .activeRoute?
                                        .id ==
                                    route.id,
                                canDelete: true
                            )
                        }
                    }
                }
                .padding(16)
                .padding(
                    .bottom,
                    24
                )
            }
            .aretScreenBackground()
            .navigationTitle(
                "Itinerari"
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .topBarTrailing
                ) {
                    ARETMark(size: 28)
                }
            }
        }
        .fileImporter(
            isPresented:
                $showGPXImporter,
            allowedContentTypes:
                [gpxType],
            allowsMultipleSelection:
                false
        ) { result in
            importGPX(result)
        }
        .alert(
            "GPX importato",
            isPresented: Binding(
                get: {
                    importedRouteName != nil
                },
                set: {
                    if !$0 {
                        importedRouteName =
                            nil
                    }
                }
            )
        ) {
            Button(
                "OK",
                role: .cancel
            ) {}
        } message: {
            Text(
                "\(importedRouteName ?? "Percorso") è stato salvato nei tuoi itinerari."
            )
        }
        .alert(
            "Importazione non riuscita",
            isPresented: Binding(
                get: {
                    importError != nil
                },
                set: {
                    if !$0 {
                        importError = nil
                    }
                }
            )
        ) {
            Button(
                "OK",
                role: .cancel
            ) {}
        } message: {
            Text(
                importError ??
                "Errore sconosciuto."
            )
        }
    }

    private var hero: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            HStack {
                ARETMark(size: 48)

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text(
                        "Trova la tua prossima linea"
                    )
                    .font(
                        .title3
                        .weight(.bold)
                    )

                    Text(
                        "Percorsi, meteo, profilo altimetrico e pianificazione in un unico posto."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }

            NavigationLink {
                RoutePlannerSearchView()
            } label: {
                HStack {
                    Image(
                        systemName:
                            "magnifyingglass"
                    )

                    Text(
                        "Cerca monte, via o percorso"
                    )

                    Spacer()

                    Image(
                        systemName:
                            "arrow.right"
                    )
                }
                .font(
                    .subheadline
                    .weight(.semibold)
                )
                .padding(.horizontal, 15)
                .frame(height: 50)
                .background(
                    Color.white
                        .opacity(0.07),
                    in: RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)

            Button {
                showGPXImporter = true
            } label: {
                Label(
                    "Importa GPX",
                    systemImage:
                        "square.and.arrow.down"
                )
                .font(
                    .subheadline
                    .weight(.semibold)
                )
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
        .aretGlassCard(
            cornerRadius: 28,
            padding: 18
        )
    }

    private var emptyPersonalRoutes:
        some View {
        HStack(spacing: 12) {
            Image(
                systemName:
                    "tray.fill"
            )
            .font(.title2)
            .foregroundStyle(
                .aretOrange
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(
                    "La tua libreria è vuota"
                )
                .font(
                    .subheadline
                    .weight(.semibold)
                )

                Text(
                    "Salva un percorso online, importa un GPX o trasforma un’attività registrata in itinerario."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .aretGlassCard(
            cornerRadius: 20,
            padding: 14
        )
    }

    private func sectionTitle(
        _ title: String
    ) -> some View {
        Text(title.uppercased())
            .font(
                .caption
                .weight(.bold)
            )
            .tracking(1.4)
            .foregroundStyle(
                .secondary
            )
            .padding(
                .leading,
                2
            )
    }

    private func routeCard(
        _ route: RouteLibraryItem,
        isActive: Bool,
        canDelete: Bool
    ) -> some View {
        Button {
            routeLibrary.select(route)
            onSelectRoute(route)
        } label: {
            VStack(
                alignment: .leading,
                spacing: 13
            ) {
                HStack(
                    alignment: .top,
                    spacing: 12
                ) {
                    ZStack {
                        RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                        .fill(
                            Color.aretOrange
                                .opacity(0.13)
                        )

                        Image(
                            systemName:
                                route.kind ==
                                .hiking
                                ? "figure.hiking"
                                : "mountain.2.fill"
                        )
                        .font(.title3)
                        .foregroundStyle(
                            .aretOrange
                        )
                    }
                    .frame(
                        width: 46,
                        height: 46
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {
                        HStack(spacing: 6) {
                            Text(route.name)
                                .font(
                                    .headline
                                )
                                .foregroundStyle(
                                    .primary
                                )

                            if isActive {
                                Text("ATTIVO")
                                    .font(
                                        .caption2
                                        .weight(.bold)
                                    )
                                    .foregroundStyle(
                                        .aretOrange
                                    )
                            }
                        }

                        Text(route.subtitle)
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                HStack(spacing: 8) {
                    miniMetric(
                        icon:
                            "point.topleft.down.to.point.bottomright.curvepath",
                        text: String(
                            format:
                                "%.1f km",
                            route
                                .distanceKilometers
                        )
                    )

                    if route
                        .ascentMeters > 0 {
                        miniMetric(
                            icon:
                                "arrow.up.right",
                            text:
                                "+\(route.ascentMeters) m"
                        )
                    }

                    if route
                        .maximumAltitudeMeters >
                        0 {
                        miniMetric(
                            icon:
                                "mountain.2.fill",
                            text:
                                "\(route.maximumAltitudeMeters) m"
                        )
                    }
                }

                if canDelete {
                    HStack {
                        Spacer()

                        Button(
                            role: .destructive
                        ) {
                            routeLibrary
                                .deletePersonalRoute(
                                    route
                                )
                        } label: {
                            Label(
                                "Elimina",
                                systemImage:
                                    "trash"
                            )
                            .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .aretGlassCard(
                cornerRadius: 22,
                padding: 15
            )
            .overlay {
                if isActive {
                    RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                    .stroke(
                        Color.aretOrange
                            .opacity(0.65),
                        lineWidth: 1.2
                    )
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func miniMetric(
        icon: String,
        text: String
    ) -> some View {
        Label(
            text,
            systemImage: icon
        )
        .font(.caption2)
        .foregroundStyle(
            .secondary
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Color.white.opacity(0.05),
            in: Capsule()
        )
    }

    private func importGPX(
        _ result:
            Result<[URL], Error>
    ) {
        do {
            guard let url =
                try result.get().first
            else {
                return
            }

            let didAccess =
                url
                    .startAccessingSecurityScopedResource()

            defer {
                if didAccess {
                    url
                        .stopAccessingSecurityScopedResource()
                }
            }

            let data =
                try Data(
                    contentsOf: url
                )

            let coordinates =
                try GPXParser()
                    .parse(data: data)

            let routeName =
                url
                    .deletingPathExtension()
                    .lastPathComponent

            guard
                routeLibrary
                    .saveImportedGPX(
                        name: routeName,
                        coordinates:
                            coordinates
                    ) != nil
            else {
                throw GPXParserError
                    .emptyTrack
            }

            importedRouteName =
                routeName
        } catch {
            importError =
                error.localizedDescription
        }
    }
}
