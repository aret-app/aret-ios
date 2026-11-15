import SwiftUI
import CoreLocation

private enum WeatherLocationMode: String {
    case automatic
    case current
    case route
    case place
}

struct WeatherView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var routeLibrary: RouteLibraryStore

    @AppStorage("aret.weather.locationMode")
    private var weatherLocationModeRaw =
        WeatherLocationMode.automatic.rawValue

    @AppStorage("aret.weather.placeName")
    private var customPlaceName = ""

    @AppStorage("aret.weather.placeLatitude")
    private var customPlaceLatitude = 0.0

    @AppStorage("aret.weather.placeLongitude")
    private var customPlaceLongitude = 0.0

    @State private var forecast: WeatherForecast?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPlaceSearch = false

    private var weatherLocationMode: WeatherLocationMode {
        WeatherLocationMode(
            rawValue: weatherLocationModeRaw
        ) ?? .automatic
    }

    var body: some View {
        NavigationStack {
            Group {
                if let forecast {
                    ScrollView {
                        VStack(
                            alignment: .leading,
                            spacing: 22
                        ) {
                            locationHeader

                            if shouldShowRouteWindow,
                               let route = routeLibrary.activeRoute {
                                weatherWindowSection(
                                    forecast: forecast,
                                    route: route
                                )
                            } else {
                                localWeatherWindowSection(forecast)
                            }

                            currentConditions(forecast)

                            hourlyForecast(
                                Array(
                                    forecast.hourly.prefix(12)
                                )
                            )

                            dailyForecast(
                                Array(
                                    forecast.daily.prefix(7)
                                )
                            )

                            sourceFooter(forecast)
                        }
                        .padding()
                    }
                    .refreshable {
                        await loadWeather()
                    }
                } else if isLoading {
                    ProgressView(
                        "Caricamento meteo…"
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                } else {
                    ContentUnavailableView(
                        "Meteo non disponibile",
                        systemImage: "cloud.sun",
                        description: Text(
                            errorMessage ??
                            "Scegli una località oppure attendi la posizione GPS."
                        )
                    )
                }
            }
            .aretScreenBackground()
            .navigationTitle("Meteo")
            .toolbar {
                ToolbarItem(
                    placement: .topBarLeading
                ) {
                    ARETMark(size: 28)
                }

                ToolbarItemGroup(
                    placement: .topBarTrailing
                ) {
                    Button {
                        showPlaceSearch = true
                    } label: {
                        Image(
                            systemName:
                                "location.magnifyingglass"
                        )
                    }
                    .accessibilityLabel(
                        "Scegli località meteo"
                    )

                    Button {
                        Task {
                            await loadWeather()
                        }
                    } label: {
                        Image(
                            systemName:
                                "arrow.clockwise"
                        )
                    }
                    .disabled(
                        isLoading ||
                        targetLocation == nil
                    )
                }
            }
        }
        .sheet(
            isPresented: $showPlaceSearch
        ) {
            WeatherPlaceSearchView {
                selection in

                customPlaceName =
                    selection.name
                customPlaceLatitude =
                    selection.latitude
                customPlaceLongitude =
                    selection.longitude
                weatherLocationModeRaw =
                    WeatherLocationMode.place.rawValue
            }
        }
        .task(id: weatherTargetKey) {
            await loadWeather()
        }
        .task {
            await hourlyRefreshLoop()
        }
    }

    private var shouldShowRouteWindow: Bool {
        switch weatherLocationMode {
        case .route:
            return routeLibrary.activeRoute != nil
        case .automatic:
            return routeLibrary.activeRoute != nil
        case .current, .place:
            return false
        }
    }

    private var targetLocation: CLLocation? {
        switch weatherLocationMode {
        case .automatic:
            return routeLocation ??
                locationManager.location

        case .current:
            return locationManager.location

        case .route:
            return routeLocation

        case .place:
            guard !customPlaceName.isEmpty else {
                return nil
            }

            return CLLocation(
                latitude: customPlaceLatitude,
                longitude: customPlaceLongitude
            )
        }
    }

    private var routeLocation: CLLocation? {
        guard
            let route =
                routeLibrary.activeRoute,
            !route.coordinates.isEmpty
        else {
            return nil
        }

        let index =
            route.coordinates.count / 2

        let coordinate =
            route.coordinates[index]

        return CLLocation(
            coordinate:
                coordinate.clLocationCoordinate,
            altitude:
                Double(
                    route.maximumAltitudeMeters
                ),
            horizontalAccuracy: 1,
            verticalAccuracy: 1,
            timestamp: Date()
        )
    }

    private var weatherTargetKey: String {
        guard let location = targetLocation else {
            return "\(weatherLocationModeRaw)-none"
        }

        let lat =
            (
                location.coordinate.latitude *
                10_000
            ).rounded() / 10_000

        let lon =
            (
                location.coordinate.longitude *
                10_000
            ).rounded() / 10_000

        return
            "\(weatherLocationModeRaw)-\(lat)-\(lon)-\(routeLibrary.activeRoute?.id ?? "no-route")"
    }

    private var locationHeader: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text(weatherLocationTitle)
                        .font(.title2.bold())

                    Text(weatherLocationSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button {
                        weatherLocationModeRaw =
                            WeatherLocationMode
                                .automatic
                                .rawValue
                    } label: {
                        Label(
                            "Automatico",
                            systemImage:
                                weatherLocationMode ==
                                .automatic
                                ? "checkmark"
                                : "sparkles"
                        )
                    }

                    Button {
                        weatherLocationModeRaw =
                            WeatherLocationMode
                                .current
                                .rawValue
                    } label: {
                        Label(
                            "Posizione attuale",
                            systemImage:
                                weatherLocationMode ==
                                .current
                                ? "checkmark"
                                : "location.fill"
                        )
                    }

                    Button {
                        weatherLocationModeRaw =
                            WeatherLocationMode
                                .route
                                .rawValue
                    } label: {
                        Label(
                            "Percorso attivo",
                            systemImage:
                                weatherLocationMode ==
                                .route
                                ? "checkmark"
                                : "figure.hiking"
                        )
                    }
                    .disabled(
                        routeLibrary.activeRoute ==
                        nil
                    )

                    Button {
                        showPlaceSearch = true
                    } label: {
                        Label(
                            "Cerca località…",
                            systemImage:
                                "magnifyingglass"
                        )
                    }

                    if !customPlaceName.isEmpty {
                        Button {
                            weatherLocationModeRaw =
                                WeatherLocationMode
                                    .place
                                    .rawValue
                        } label: {
                            Label(
                                customPlaceName,
                                systemImage:
                                    weatherLocationMode ==
                                    .place
                                    ? "checkmark"
                                    : "mappin.and.ellipse"
                            )
                        }
                    }
                } label: {
                    Image(
                        systemName:
                            "location.magnifyingglass"
                    )
                    .font(.title3.weight(.semibold))
                    .frame(
                        width: 42,
                        height: 42
                    )
                    .background(
                        .thinMaterial,
                        in: Circle()
                    )
                }
                .accessibilityLabel(
                    "Scegli località meteo"
                )
            }

            if weatherLocationMode == .place {
                Button {
                    showPlaceSearch = true
                } label: {
                    Label(
                        "Cambia località",
                        systemImage:
                            "magnifyingglass"
                    )
                    .font(.caption.weight(.semibold))
                }
            }
        }
    }

    private var weatherLocationTitle: String {
        switch weatherLocationMode {
        case .automatic:
            if let route =
                routeLibrary.activeRoute {
                return route.name
            }
            return "Posizione attuale"

        case .current:
            return "Posizione attuale"

        case .route:
            return routeLibrary
                .activeRoute?
                .name ??
                "Percorso attivo"

        case .place:
            return customPlaceName.isEmpty
                ? "Località"
                : customPlaceName
        }
    }

    private var weatherLocationSubtitle: String {
        switch weatherLocationMode {
        case .automatic:
            return routeLibrary.activeRoute != nil
                ? "Meteo del percorso · automatico"
                : "Meteo della tua posizione · automatico"

        case .current:
            return "Meteo della tua posizione"

        case .route:
            return "Meteo del percorso selezionato"

        case .place:
            return "Località scelta manualmente"
        }
    }

    private func currentConditions(
        _ forecast: WeatherForecast
    ) -> some View {
        let current = forecast.current

        return VStack(spacing: 18) {
            HStack(
                alignment: .center,
                spacing: 18
            ) {
                Image(
                    systemName:
                        current.symbolName
                )
                .font(.system(size: 48))
                .symbolRenderingMode(
                    .hierarchical
                )

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text(
                        current
                            .temperatureCelsius,
                        format:
                            .number
                            .precision(
                                .fractionLength(0)
                            )
                    )
                    .font(
                        .system(
                            size: 52,
                            weight: .light
                        )
                    )
                    .monospacedDigit()
                    .overlay(
                        alignment:
                            .topTrailing
                    ) {
                        Text("°")
                            .font(.title2)
                            .offset(
                                x: 18,
                                y: 2
                            )
                    }

                    Text(
                        current.conditionName
                    )
                    .font(.headline)
                    .foregroundStyle(
                        .secondary
                    )
                }

                Spacer()
            }

            HStack(spacing: 10) {
                weatherMetric(
                    title: "Vento",
                    value:
                        "\(Int(current.windSpeedKPH.rounded()))",
                    unit: "km/h",
                    icon: "wind"
                )

                weatherMetric(
                    title: "Raffiche",
                    value:
                        "\(Int(current.windGustKPH.rounded()))",
                    unit: "km/h",
                    icon: "wind.circle"
                )

                weatherMetric(
                    title: "Precip.",
                    value: String(
                        format: "%.1f",
                        current.precipitationMM
                    ),
                    unit: "mm",
                    icon: "drop.fill"
                )
            }
        }
        .padding(18)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }

    private func localWeatherWindowSection(
        _ forecast: WeatherForecast
    ) -> some View {
        let todayKey = dateKey(
            date: Date(),
            timezoneIdentifier: forecast.timezone
        )
        let todayHours = forecast.hourly.filter {
            $0.dateKey == todayKey
        }
        let window = WeatherWindowEngine.bestWindow(
            hours: todayHours,
            routeKind: .hiking
        )

        return MountainWeatherDashboard(
            hours: todayHours,
            window: window,
            route: nil,
            retrievedAt: forecast.current.fetchedAt,
            samplingPoints: 1
        )
    }

    private func weatherWindowSection(
        forecast: WeatherForecast,
        route: RouteLibraryItem
    ) -> some View {
        let todayKey = dateKey(
            date: Date(),
            timezoneIdentifier: forecast.timezone
        )
        let todayHours = forecast.hourly.filter {
            $0.dateKey == todayKey
        }
        let window = WeatherWindowEngine.bestWindow(
            hours: todayHours,
            routeKind: route.kind
        )

        return MountainWeatherDashboard(
            hours: todayHours,
            window: window,
            route: route,
            retrievedAt: forecast.current.fetchedAt,
            samplingPoints: forecast.samplingPointCount
        )
    }

    private func hourlyForecast(
        _ hours: [HourlyWeather]
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("Prossime 12 ore")
                .font(.headline)

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: 10) {
                    ForEach(hours) { hour in
                        VStack(spacing: 9) {
                            Text(
                                hour.timeLabel
                            )
                            .font(
                                .caption
                                .weight(.semibold)
                            )
                            .monospacedDigit()

                            Image(
                                systemName:
                                    hour.symbolName
                            )
                            .font(.title3)
                            .frame(height: 28)

                            Text(
                                "\(Int(hour.temperatureCelsius.rounded()))°"
                            )
                            .font(.headline)
                            .monospacedDigit()

                            Label(
                                "\(hour.precipitationProbability)%",
                                systemImage:
                                    "drop.fill"
                            )
                            .font(.caption2)
                            .foregroundStyle(
                                .secondary
                            )

                            Label(
                                "\(Int(hour.windGustKPH.rounded()))",
                                systemImage: "wind"
                            )
                            .font(.caption2)
                            .foregroundStyle(
                                .secondary
                            )
                        }
                        .frame(width: 74)
                        .padding(.vertical, 12)
                        .background(
                            .thinMaterial,
                            in:
                                RoundedRectangle(
                                    cornerRadius: 18,
                                    style:
                                        .continuous
                                )
                        )
                    }
                }
            }
        }
    }

    private func dailyForecast(
        _ days: [DailyWeather]
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("7 giorni")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(days) { day in
                    HStack(spacing: 12) {
                        VStack(
                            alignment: .leading,
                            spacing: 3
                        ) {
                            Text(day.dateLabel)
                                .font(.headline)

                            Text(
                                day.conditionName
                            )
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                        }
                        .frame(
                            width: 90,
                            alignment: .leading
                        )

                        Image(
                            systemName:
                                day.symbolName
                        )
                        .font(.title3)
                        .frame(width: 30)

                        Spacer()

                        VStack(
                            alignment: .trailing,
                            spacing: 3
                        ) {
                            Text(
                                "\(Int(day.temperatureMinCelsius.rounded()))° / \(Int(day.temperatureMaxCelsius.rounded()))°"
                            )
                            .font(
                                .subheadline
                                .weight(.semibold)
                            )
                            .monospacedDigit()

                            Text(
                                "Pioggia \(day.precipitationProbabilityMax)% · raffiche \(Int(day.windGustMaxKPH.rounded())) km/h"
                            )
                            .font(.caption2)
                            .foregroundStyle(
                                .secondary
                            )
                        }
                    }
                    .padding(14)
                    .background(
                        .thinMaterial,
                        in:
                            RoundedRectangle(
                                cornerRadius: 18,
                                style:
                                    .continuous
                            )
                    )
                }
            }
        }
    }

    private func sourceFooter(
        _ forecast: WeatherForecast
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 5
        ) {
            Label(
                "Ultimo aggiornamento: \(forecast.current.fetchedAt.formatted(date: .omitted, time: .shortened))",
                systemImage: "clock"
            )

            Text(
                "Previsione per la località mostrata sopra. In montagna le condizioni possono cambiare rapidamente: ARET non sostituisce bollettini e allerte ufficiali."
            )
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func weatherMetric(
        title: String,
        value: String,
        unit: String,
        icon: String
    ) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.headline)

            HStack(
                alignment:
                    .firstTextBaseline,
                spacing: 2
            ) {
                Text(value)
                    .font(.headline)
                    .monospacedDigit()

                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(
                        .secondary
                    )
            }

            Text(title)
                .font(.caption2)
                .foregroundStyle(
                    .secondary
                )
        }
        .frame(maxWidth: .infinity)
    }

    private func dateKey(
        date: Date,
        timezoneIdentifier: String
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale =
            Locale(
                identifier:
                    "en_US_POSIX"
            )
        formatter.calendar =
            Calendar(
                identifier:
                    .gregorian
            )
        formatter.timeZone =
            TimeZone(
                identifier:
                    timezoneIdentifier
            ) ?? .current
        formatter.dateFormat =
            "yyyy-MM-dd"

        return formatter.string(
            from: date
        )
    }

    private func hourlyRefreshLoop()
        async {
        while !Task.isCancelled {
            try? await Task.sleep(
                nanoseconds:
                    3_600_000_000_000
            )

            guard !Task.isCancelled
            else {
                return
            }

            await loadWeather()
        }
    }

    private func loadWeather()
        async {
        guard let location =
                targetLocation
        else {
            forecast = nil
            errorMessage =
                weatherLocationMode ==
                    .route
                ? "Seleziona un percorso per usare il meteo del percorso."
                : "Posizione non disponibile. Scegli una località meteo."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            if shouldShowRouteWindow,
               let route = routeLibrary.activeRoute,
               route.coordinates.count > 1 {
                forecast = try await FieldWeatherService.shared
                    .forecastAlongRoute(route)
            } else {
                forecast = try await FieldWeatherService.shared
                    .forecast(at: location)
            }
        } catch {
            forecast = nil
            errorMessage =
                "Impossibile caricare le previsioni: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
