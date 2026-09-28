import SwiftUI
import CoreLocation

struct WeatherView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var routeLibrary: RouteLibraryStore

    @State private var forecast: WeatherForecast?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if let forecast {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            locationHeader
                            currentConditions(forecast)
                            hourlyForecast(forecast.hourly)
                            dailyForecast(forecast.daily)
                            sourceFooter(forecast)
                        }
                        .padding()
                    }
                    .refreshable {
                        await loadWeather()
                    }
                } else if isLoading {
                    ProgressView("Caricamento meteo…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ContentUnavailableView(
                        "Meteo non disponibile",
                        systemImage: "cloud.sun",
                        description: Text(
                            errorMessage ??
                            "Seleziona un percorso oppure attendi la posizione GPS."
                        )
                    )
                }
            }
            .navigationTitle("Meteo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await loadWeather()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading || targetLocation == nil)
                }
            }
        }
        .task(id: weatherTargetKey) {
            await loadWeather()
        }
    }

    private var targetLocation: CLLocation? {
        if let route = routeLibrary.activeRoute,
           !route.coordinates.isEmpty {
            let index = route.coordinates.count / 2
            let coordinate = route.coordinates[index]

            return CLLocation(
                coordinate: coordinate.clLocationCoordinate,
                altitude: Double(route.maximumAltitudeMeters),
                horizontalAccuracy: 1,
                verticalAccuracy: 1,
                timestamp: Date()
            )
        }

        return locationManager.location
    }

    private var weatherTargetKey: String {
        if let route = routeLibrary.activeRoute {
            return "route-\(route.id)"
        }

        guard let location = locationManager.location else {
            return "no-location"
        }

        let lat = (location.coordinate.latitude * 100).rounded() / 100
        let lon = (location.coordinate.longitude * 100).rounded() / 100
        return "location-\(lat)-\(lon)"
    }

    private var locationHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let route = routeLibrary.activeRoute {
                Text(route.name)
                    .font(.title2.bold())

                Text("Meteo del percorso")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Posizione attuale")
                    .font(.title2.bold())

                Text("Seleziona un percorso per vedere il meteo della montagna.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func currentConditions(
        _ forecast: WeatherForecast
    ) -> some View {
        let current = forecast.current

        return VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 18) {
                Image(systemName: current.symbolName)
                    .font(.system(size: 48))
                    .symbolRenderingMode(.hierarchical)

                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        current.temperatureCelsius,
                        format: .number.precision(.fractionLength(0))
                    )
                    .font(.system(size: 52, weight: .light))
                    .monospacedDigit()
                    .overlay(alignment: .topTrailing) {
                        Text("°")
                            .font(.title2)
                            .offset(x: 18, y: 2)
                    }

                    Text(current.conditionName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                weatherMetric(
                    title: "Vento",
                    value: "\(Int(current.windSpeedKPH.rounded()))",
                    unit: "km/h",
                    icon: "wind"
                )

                weatherMetric(
                    title: "Raffiche",
                    value: "\(Int(current.windGustKPH.rounded()))",
                    unit: "km/h",
                    icon: "wind.circle"
                )

                weatherMetric(
                    title: "Precip.",
                    value: String(format: "%.1f", current.precipitationMM),
                    unit: "mm",
                    icon: "drop.fill"
                )
            }
        }
        .padding(18)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private func hourlyForecast(
        _ hours: [HourlyWeather]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prossime 12 ore")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(hours) { hour in
                        VStack(spacing: 9) {
                            Text(hour.timeLabel)
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()

                            Image(systemName: hour.symbolName)
                                .font(.title3)
                                .frame(height: 28)

                            Text("\(Int(hour.temperatureCelsius.rounded()))°")
                                .font(.headline)
                                .monospacedDigit()

                            Label(
                                "\(hour.precipitationProbability)%",
                                systemImage: "drop.fill"
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                            Label(
                                "\(Int(hour.windGustKPH.rounded()))",
                                systemImage: "wind"
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        .frame(width: 74)
                        .padding(.vertical, 12)
                        .background(
                            .thinMaterial,
                            in: RoundedRectangle(
                                cornerRadius: 18,
                                style: .continuous
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
        VStack(alignment: .leading, spacing: 12) {
            Text("3 giorni")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(days) { day in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(day.dateLabel)
                                .font(.headline)

                            Text(day.conditionName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 90, alignment: .leading)

                        Image(systemName: day.symbolName)
                            .font(.title3)
                            .frame(width: 30)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(
                                "\(Int(day.temperatureMinCelsius.rounded()))° / \(Int(day.temperatureMaxCelsius.rounded()))°"
                            )
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()

                            Text(
                                "Pioggia \(day.precipitationProbabilityMax)% · raffiche \(Int(day.windGustMaxKPH.rounded())) km/h"
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .background(
                        .thinMaterial,
                        in: RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                    )
                }
            }
        }
    }

    private func sourceFooter(
        _ forecast: WeatherForecast
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(
                "Ultimo aggiornamento: \(forecast.current.fetchedAt.formatted(date: .omitted, time: .shortened))",
                systemImage: "clock"
            )

            Text(
                "Previsione riferita al percorso selezionato quando disponibile. In montagna le condizioni possono cambiare rapidamente: ARET non sostituisce bollettini e allerte ufficiali."
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

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .monospacedDigit()
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadWeather() async {
        guard let location = targetLocation else {
            forecast = nil
            errorMessage = "Posizione non ancora disponibile."
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
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
