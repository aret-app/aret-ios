import SwiftUI
import CoreLocation

enum OutdoorExperienceLevel: String, CaseIterable, Identifiable {
    case beginner = "Base"
    case intermediate = "Intermedio"
    case advanced = "Esperto"

    var id: String { rawValue }
}

struct RoutePlannerSearchView: View {
    @EnvironmentObject private var routeLibrary: RouteLibraryStore

    @State private var searchText = ""
    @State private var onlineRoutes: [RouteLibraryItem] = []
    @State private var isSearchingOnline = false
    @State private var onlineError: String?

    private var localRoutes: [RouteLibraryItem] {
        let all =
            routeLibrary.catalogRoutes +
            routeLibrary.personalRoutes

        let trimmed =
            searchText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return all
        }

        return all.filter {
            $0.name.localizedCaseInsensitiveContains(
                trimmed
            ) ||
            $0.subtitle.localizedCaseInsensitiveContains(
                trimmed
            )
        }
    }

    var body: some View {
        List {
            if searchText.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {
                Section {
                    Text(
                        "Scrivi una montagna, una località o il nome di un sentiero. ARET cerca prima nella tua libreria e, quando premi Cerca, anche tra i percorsi hiking aperti di OpenStreetMap."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }

            if !localRoutes.isEmpty {
                Section("ARET e miei percorsi") {
                    ForEach(localRoutes) { route in
                        NavigationLink {
                            RoutePlanningView(
                                route: route
                            )
                        } label: {
                            plannerRouteRow(route)
                        }
                    }
                }
            }

            if isSearchingOnline {
                Section("Percorsi online") {
                    HStack {
                        ProgressView()
                        Text(
                            "Cerco percorsi aperti…"
                        )
                        .foregroundStyle(.secondary)
                    }
                }
            } else if !onlineRoutes.isEmpty {
                Section {
                    ForEach(onlineRoutes) { route in
                        NavigationLink {
                            RoutePlanningView(
                                route: route
                            )
                        } label: {
                            plannerRouteRow(route)
                        }
                    }
                } header: {
                    Text("Percorsi online")
                } footer: {
                    Text(
                        "Dati percorso © OpenStreetMap contributors, licenza ODbL. D+ e quota non sono stimati finché la sorgente non fornisce un profilo altimetrico affidabile."
                    )
                }
            }

            if let onlineError {
                Section("Ricerca online") {
                    Text(onlineError)
                        .foregroundStyle(.secondary)

                    Button {
                        Task {
                            await searchOnline()
                        }
                    } label: {
                        Label(
                            "Riprova",
                            systemImage:
                                "arrow.clockwise"
                        )
                    }
                }
            }

            if !searchText.isEmpty &&
               localRoutes.isEmpty &&
               onlineRoutes.isEmpty &&
               !isSearchingOnline &&
               onlineError == nil {
                Section {
                    Text(
                        "Premi Cerca sulla tastiera per cercare percorsi online nella zona indicata."
                    )
                    .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Pianifica")
        .searchable(
            text: $searchText,
            placement:
                .navigationBarDrawer(
                    displayMode: .always
                ),
            prompt:
                "Es. Pania della Croce"
        )
        .onSubmit(of: .search) {
            Task {
                await searchOnline()
            }
        }
        .onChange(of: searchText) {
            _, _ in
            onlineRoutes = []
            onlineError = nil
        }
    }

    private func plannerRouteRow(
        _ route: RouteLibraryItem
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 5
        ) {
            HStack {
                Text(plannedRoute.name)
                    .font(.headline)

                if route.origin ==
                    .openStreetMap {
                    Text("OSM")
                        .font(
                            .caption2
                            .weight(.bold)
                        )
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            .orange.opacity(0.16),
                            in: Capsule()
                        )
                        .foregroundStyle(
                            .orange
                        )
                }
            }

            Text(plannedRoute.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            if route.origin ==
                .openStreetMap {
                Text(
                    String(
                        format:
                            "%.1f km · profilo altimetrico da verificare",
                        plannedRoute.distanceKilometers
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                Text(
                    String(
                        format:
                            "%.1f km · +%d m · max %d m",
                        route.distanceKilometers,
                        route.ascentMeters,
                        route.maximumAltitudeMeters
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @MainActor
    private func searchOnline() async {
        let trimmed =
            searchText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return
        }

        isSearchingOnline = true
        onlineError = nil
        onlineRoutes = []

        do {
            onlineRoutes =
                try await
                OnlineRouteSearchService
                    .shared
                    .search(query: trimmed)

            if onlineRoutes.isEmpty {
                onlineError =
                    "Nessun percorso hiking OpenStreetMap trovato entro circa 25 km dalla località."
            }
        } catch {
            onlineError =
                "Ricerca online non riuscita: \(error.localizedDescription)"
        }

        isSearchingOnline = false
    }
}

struct RoutePlanningView: View {
    @EnvironmentObject private var routeLibrary: RouteLibraryStore

    let route: RouteLibraryItem

    @State private var selectedDate = Date()
    @State private var experienceLevel: OutdoorExperienceLevel = .intermediate
    @State private var forecast: WeatherForecast?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var terrainProfile: TerrainElevationProfile?
    @State private var isLoadingTerrain = false
    @State private var terrainError: String?

    private var plannedRoute: RouteLibraryItem {
        var value = route

        if let terrainProfile {
            value.ascentMeters =
                Int(terrainProfile.ascentMeters.rounded())
            value.minimumAltitudeMeters =
                Int(terrainProfile.minimumAltitudeMeters.rounded())
            value.maximumAltitudeMeters =
                Int(terrainProfile.maximumAltitudeMeters.rounded())
            value.coordinates =
                terrainProfile.coordinates
        }

        return value
    }

    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 15, to: start) ?? start
        return start...end
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                routeHeader
                planningControls

                if let forecast {
                    plannedDayWeather(forecast)

                    let hours = hoursForSelectedDate(forecast)
                    let window = WeatherWindowEngine.bestWindow(
                        hours: hours,
                        routeKind: plannedRoute.kind
                    )

                    weatherWindowCard(
                        window: window,
                        hours: hours
                    )

                    selectedDayHourly(hours)
                } else if isLoading {
                    ProgressView("Aggiornamento previsioni…")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        ContentUnavailableView(
                            "Meteo non disponibile",
                            systemImage: "cloud.slash",
                            description: Text(errorMessage)
                        )

                        Button {
                            Task {
                                await loadWeather()
                            }
                        } label: {
                            Label(
                                "Riprova meteo",
                                systemImage: "arrow.clockwise"
                            )
                        }
                        .buttonStyle(.bordered)
                    }
                }

                levelCompatibilitySection

                if plannedRoute.origin == .openStreetMap {
                    Button {
                        _ = routeLibrary.saveOnlineRoute(plannedRoute)
                    } label: {
                        Label(
                            "Salva nei miei percorsi",
                            systemImage: "square.and.arrow.down"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    routeLibrary.select(plannedRoute)
                } label: {
                    Label(
                        "Usa questo percorso sulla mappa",
                        systemImage: "map.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Text(
                    "La finestra meteo è un'indicazione automatica basata sulle previsioni orarie e non certifica che la salita sia sicura. Per attività tecniche vanno sempre considerati bollettini ufficiali, condizioni del terreno e valutazione sul posto."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Pianifica")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: selectedDateKeyForTask) {
            await loadWeather()
        }
        .task(id: route.id) {
            await loadTerrainProfileIfNeeded()
        }
        .task {
            await hourlyRefreshLoop()
        }
    }

    private var routeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(route.name)
                .font(.largeTitle.bold())

            Text(route.subtitle)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                infoPill(
                    String(
                        format: "%.1f km",
                        route.distanceKilometers
                    ),
                    icon: "point.topleft.down.to.point.bottomright.curvepath"
                )

                if plannedRoute.ascentMeters > 0 {
                    infoPill(
                        "+\(plannedRoute.ascentMeters) m",
                        icon: "arrow.up.right"
                    )
                }

                if plannedRoute.maximumAltitudeMeters > 0 {
                    infoPill(
                        "\(plannedRoute.maximumAltitudeMeters) m",
                        icon: "mountain.2.fill"
                    )
                }
            }

            if plannedRoute.origin == .openStreetMap {
                if isLoadingTerrain {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Calcolo profilo altimetrico DEM…")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else if let terrainProfile {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(
                            "Profilo DEM · +\(Int(terrainProfile.ascentMeters.rounded())) m / -\(Int(terrainProfile.descentMeters.rounded())) m · \(Int(terrainProfile.minimumAltitudeMeters.rounded()))–\(Int(terrainProfile.maximumAltitudeMeters.rounded())) m"
                        )
                        .font(.caption.weight(.semibold))

                        Text(
                            "\(terrainProfile.sourceName) · \(terrainProfile.sampledPointCount) campioni"
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                } else if let terrainError {
                    Text(
                        "Profilo altimetrico non disponibile: \(terrainError)"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else {
                    Text(
                        "Percorso aperto da OpenStreetMap. ARET calcola D+, D- e quote con un DEM esterno quando apri il percorso."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var planningControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quando vuoi andare?")
                .font(.headline)

            DatePicker(
                "Data",
                selection: $selectedDate,
                in: dateRange,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)

            Divider()

            Text("Il tuo livello")
                .font(.headline)

            Picker("Livello", selection: $experienceLevel) {
                ForEach(OutdoorExperienceLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    @ViewBuilder
    private func plannedDayWeather(
        _ forecast: WeatherForecast
    ) -> some View {
        let dayKey = selectedDateKey(
            timezoneIdentifier: forecast.timezone
        )

        if let day = forecast.daily.first(where: { $0.rawDate == dayKey }) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Previsione del giorno")
                    .font(.headline)

                HStack(spacing: 14) {
                    Image(systemName: day.symbolName)
                        .font(.system(size: 34))
                        .symbolRenderingMode(.hierarchical)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(day.conditionName)
                            .font(.headline)

                        Text(
                            "\(Int(day.temperatureMinCelsius.rounded()))° / \(Int(day.temperatureMaxCelsius.rounded()))°"
                        )
                        .monospacedDigit()
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Label(
                            "\(day.precipitationProbabilityMax)%",
                            systemImage: "drop.fill"
                        )

                        Label(
                            "\(Int(day.windGustMaxKPH.rounded())) km/h",
                            systemImage: "wind"
                        )
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
        } else {
            ContentUnavailableView(
                "Previsione non disponibile",
                systemImage: "calendar.badge.exclamationmark",
                description: Text(
                    "La data scelta è fuori dall'orizzonte meteo attualmente disponibile."
                )
            )
        }
    }

    private func weatherWindowCard(
        window: WeatherWindow,
        hours: [HourlyWeather]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Finestra meteo favorevole")
                        .font(.headline)

                    Text(window.quality.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(
                            window.quality == .favorable
                            ? .green
                            : .orange
                        )
                }

                Spacer()

                Image(systemName: "clock.badge.checkmark")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }

            Text(window.timeRangeText)
                .font(.system(size: 30, weight: .semibold))
                .monospacedDigit()

            if !window.reasons.isEmpty {
                Text(window.reasons.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let freezing = representativeFreezingLevel(hours) {
                Label(
                    "Zero termico indicativo: \(Int(freezing.rounded())) m",
                    systemImage: "snowflake"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Text(
                "Ricalcolata automaticamente quando arrivano nuove previsioni e almeno ogni ora mentre ARET è aperta."
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private func selectedDayHourly(
        _ hours: [HourlyWeather]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previsione oraria")
                .font(.headline)

            if hours.isEmpty {
                Text("Nessun dato orario disponibile.")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(hours) { hour in
                            VStack(spacing: 8) {
                                Text(hour.timeLabel)
                                    .font(.caption.weight(.semibold))
                                    .monospacedDigit()

                                Image(systemName: hour.symbolName)
                                    .font(.title3)

                                Text(
                                    "\(Int(hour.temperatureCelsius.rounded()))°"
                                )
                                .font(.headline)

                                Label(
                                    "\(hour.precipitationProbability)%",
                                    systemImage: "drop.fill"
                                )
                                .font(.caption2)

                                Label(
                                    "\(Int(hour.windGustKPH.rounded()))",
                                    systemImage: "wind"
                                )
                                .font(.caption2)
                            }
                            .frame(width: 74)
                            .padding(.vertical, 11)
                            .background(
                                .thinMaterial,
                                in: RoundedRectangle(
                                    cornerRadius: 16,
                                    style: .continuous
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    private var levelCompatibilitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Via più adatta al tuo livello")
                .font(.headline)

            Text("Livello selezionato: \(experienceLevel.rawValue)")
                .font(.subheadline.weight(.semibold))

            Text(
                "ARET userà grado tecnico, terreno, esposizione, protezioni, lunghezza, dislivello e fonti verificate per confrontare le vie verso la stessa meta. In questa beta non inventiamo una raccomandazione tecnica usando solo distanza e D+."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text(
                "Impegno fisico del percorso attuale: \(physicalEffortLabel)"
            )
            .font(.caption.weight(.semibold))
        }
        .padding(16)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private var physicalEffortLabel: String {
        if plannedRoute.ascentMeters >= 1_200 || plannedRoute.distanceKilometers >= 16 {
            return "elevato"
        }

        if plannedRoute.ascentMeters >= 600 || plannedRoute.distanceKilometers >= 8 {
            return "medio"
        }

        return "contenuto"
    }

    private var selectedDateKeyForTask: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(plannedRoute.id)-\(plannedRoute.maximumAltitudeMeters)-\(formatter.string(from: selectedDate))"
    }

    private func hoursForSelectedDate(
        _ forecast: WeatherForecast
    ) -> [HourlyWeather] {
        let key = selectedDateKey(
            timezoneIdentifier: forecast.timezone
        )

        return forecast.hourly.filter {
            $0.dateKey == key
        }
    }

    private func selectedDateKey(
        timezoneIdentifier: String
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone =
            TimeZone(identifier: timezoneIdentifier) ?? .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }

    private func representativeFreezingLevel(
        _ hours: [HourlyWeather]
    ) -> Double? {
        let values = hours.compactMap(\.freezingLevelMeters)

        guard !values.isEmpty else { return nil }

        return values.reduce(0, +) / Double(values.count)
    }

    private func targetLocation() -> CLLocation? {
        guard !plannedRoute.coordinates.isEmpty else {
            return nil
        }

        let midpoint =
            plannedRoute.coordinates[
                plannedRoute.coordinates.count / 2
            ]

        if plannedRoute.maximumAltitudeMeters > 0 {
            return CLLocation(
                coordinate:
                    midpoint.clLocationCoordinate,
                altitude:
                    Double(
                        plannedRoute.maximumAltitudeMeters
                    ),
                horizontalAccuracy: 1,
                verticalAccuracy: 1,
                timestamp: Date()
            )
        }

        return CLLocation(
            latitude: midpoint.latitude,
            longitude: midpoint.longitude
        )
    }

    private func loadTerrainProfileIfNeeded() async {
        guard
            route.origin == .openStreetMap,
            route.coordinates.count > 1
        else {
            return
        }

        isLoadingTerrain = true
        terrainError = nil

        do {
            terrainProfile =
                try await TerrainElevationService
                    .shared
                    .profile(
                        coordinates: route.coordinates
                    )

            // Refresh weather at the now-known mountain altitude.
            await loadWeather()
        } catch {
            terrainProfile = nil
            terrainError = error.localizedDescription
        }

        isLoadingTerrain = false
    }

    private func loadWeather() async {
        guard let location = targetLocation() else {
            forecast = nil
            errorMessage = "Il percorso non contiene coordinate utilizzabili."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            forecast = try await FieldWeatherService.shared.forecast(
                at: location
            )
        } catch {
            forecast = nil
            errorMessage =
                "Non riesco a scaricare le previsioni per questo itinerario: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func hourlyRefreshLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(
                nanoseconds: 3_600_000_000_000
            )

            guard !Task.isCancelled else { return }
            await loadWeather()
        }
    }

    private func infoPill(
        _ text: String,
        icon: String
    ) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                .thinMaterial,
                in: Capsule()
            )
    }
}
