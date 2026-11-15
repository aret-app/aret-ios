import SwiftUI
import Charts

/// Route-specific weather decision support. All observations are forecasts.
/// No label in this view certifies the route as safe or accessible.
struct MountainWeatherDashboard: View {
    let hours: [HourlyWeather]
    let window: WeatherWindow
    let route: RouteLibraryItem
    let retrievedAt: Date

    private var assessment: HikingWeatherAssessment {
        HikingWeatherAssessment.evaluate(
            hours: hours,
            window: window,
            maximumRouteAltitudeMeters: route.maximumAltitudeMeters
        )
    }

    private var daylightHours: [HourlyWeather] {
        hours.filter { hour in
            if let isDaylight = hour.isDaylight {
                return isDaylight
            }
            guard let clock = hour.hour else { return false }
            return clock >= 6 && clock <= 19
        }
    }

    private var hoursForMetrics: [HourlyWeather] {
        guard
            window.quality != .noClearWindow,
            let start = window.startTime,
            let end = window.endTime
        else {
            return daylightHours
        }

        // Time labels are provider-local HH:mm values.
        let selected = daylightHours.filter {
            $0.timeLabel >= start && $0.timeLabel < end
        }
        return selected.isEmpty ? daylightHours : selected
    }

    private var maxGust: Double? {
        hoursForMetrics.map(\.windGustKPH).max()
    }

    private var freezingLevel: Double? {
        hoursForMetrics.compactMap(\.freezingLevelMeters).min()
    }

    private var visibility: Double? {
        hoursForMetrics.compactMap(\.visibilityMeters).min()
    }

    private var maxPrecipitationProbability: Int? {
        hoursForMetrics.map(\.precipitationProbability).max()
    }

    private var estimateHours: Double? {
        guard route.distanceKilometers > 0.5,
              route.kind == .hiking else { return nil }

        // Rough moving-time estimate, NOT a verified schedule.
        // It covers only the geometry mapped in the GPX/OSM relation:
        // an ascent-only route may omit the descent.
        let horizontal = route.distanceKilometers / 4.0
        let vertical = Double(max(route.ascentMeters, 0)) / 600.0
        return max(0.5, horizontal + vertical)
    }

    private var windowHours: Double? {
        guard
            let start = window.startTime,
            let end = window.endTime,
            let startHour = Int(start.prefix(2)),
            let endHour = Int(end.prefix(2)),
            endHour > startHour
        else {
            return nil
        }
        return Double(endHour - startHour)
    }

    private var advisoryColor: Color {
        assessment.guidance.color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            header
            verdictHero
            essentialsGrid
            timeline

            if let estimateHours, let windowHours {
                durationContext(
                    estimated: estimateHours,
                    window: windowHours
                )
            }

            reasons

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                    Text(
                        "Dati recuperati \(retrievedAt.formatted(date: .abbreviated, time: .shortened))"
                    )
                }
                .foregroundStyle(.secondary)

                Text(
                    "Modelli meteorologici e soglie indicative, NON un via libera. Verifica bollettini ufficiali, vento sulle creste, neve/ghiaccio, durata del rientro e condizioni locali. Dati atmosferici in quota ≠ raffiche effettive in vetta."
                )
                .foregroundStyle(.secondary)
            }
            .font(.caption2)
            .padding(.horizontal, 2)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ARETMark(size: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text("ARET MOUNTAIN WEATHER")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)

                Text("Previsioni per il percorso selezionato")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "mountain.2.fill")
                .foregroundStyle(.aretOrange)
        }
    }

    private var verdictHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 11) {
                ZStack {
                    Circle()
                        .fill(advisoryColor.opacity(0.16))
                        .frame(width: 48, height: 48)

                    Image(systemName: assessment.guidance.symbol)
                        .font(.title2)
                        .foregroundStyle(advisoryColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("VALUTAZIONE METEO")
                        .font(.caption2.weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.62))

                    Text(assessment.guidance.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(.white.opacity(0.13))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 5) {
                Text(
                    window.quality == .noClearWindow
                        ? "NESSUNA FINESTRA CONTINUA INDIVIDUATA"
                        : "FINESTRA METEO DA VALUTARE"
                )
                .font(.caption2.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.68))

                Text(window.timeRangeText)
                    .font(
                        .system(
                            size: 37,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)

                Text(
                    "La finestra descrive solo il meteo: non verifica tempi di avvicinamento, vetta e ritorno."
                )
                .font(.caption)
                .foregroundStyle(.white.opacity(0.66))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.aretSurface,
                            Color.aretBackground,
                            advisoryColor.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .strokeBorder(
                    advisoryColor.opacity(0.43),
                    lineWidth: 1
                )
        }
        .shadow(color: advisoryColor.opacity(0.08), radius: 22, y: 9)
    }

    private var essentialsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ],
            spacing: 10
        ) {
            metric(
                title: "RAFFICHE A 10 M",
                value: maxGust.map {
                    "\(Int($0.rounded()))"
                } ?? "—",
                unit: "km/h",
                symbol: "wind"
            )

            metric(
                title: "ZERO TERMICO",
                value: freezingLevel.map {
                    "\(Int($0.rounded()))"
                } ?? "—",
                unit: "m",
                symbol: "snowflake"
            )

            metric(
                title: "PRECIPITAZIONI",
                value: maxPrecipitationProbability.map {
                    "\($0)"
                } ?? "—",
                unit: "%",
                symbol: "cloud.rain.fill"
            )

            metric(
                title: "VISIBILITÀ MIN",
                value: visibility.map {
                    String(format: "%.1f", $0 / 1_000)
                } ?? "—",
                unit: "km",
                symbol: "eye.fill"
            )

            if let wind = assessment.windAloftKPH,
               let height = assessment.windAloftHeightMeters {
                HStack(spacing: 9) {
                    Image(systemName: "wind")
                        .foregroundStyle(.aretOrange)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("VENTO SUL LIVELLO ATMOSFERICO")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)

                        Text(
                            "\(Int(wind.rounded())) km/h a circa \(Int(height.rounded())) m"
                        )
                        .font(.subheadline.weight(.semibold))
                    }

                    Spacer()
                }
                .padding(13)
                .background(
                    Color.aretSurface,
                    in: RoundedRectangle(cornerRadius: 17)
                )
                .gridCellColumns(2)
            }
        }
    }

    private func metric(
        title: String,
        value: String,
        unit: String,
        symbol: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .foregroundStyle(.aretOrange)

                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value)
                    .font(
                        .system(
                            size: 26,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(
            Color.aretSurface,
            in: RoundedRectangle(cornerRadius: 17)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 17)
                .stroke(.white.opacity(0.075), lineWidth: 0.8)
        }
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("ORA PER ORA")
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Previsioni locali")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(daylightHours) { hour in
                        hourTile(hour)
                    }
                }
            }
        }
        .aretGlassCard(cornerRadius: 21, padding: 14)
    }

    private func hourTile(_ hour: HourlyWeather) -> some View {
        let flagged = hour.weatherCode >= 95 ||
            hour.windGustKPH >= 65 ||
            (hour.visibilityMeters ?? 10_000) < 1_000

        return VStack(spacing: 8) {
            Text(hour.timeLabel)
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Image(systemName: hour.symbolName)
                .font(.title3)
                .foregroundStyle(flagged ? .red : .aretOrange)
                .frame(height: 22)

            Text("\(Int(hour.temperatureCelsius.rounded()))°")
                .font(.subheadline.weight(.bold))
                .monospacedDigit()

            Label(
                "\(Int(hour.windGustKPH.rounded()))",
                systemImage: "wind"
            )

            Label(
                "\(hour.precipitationProbability)%",
                systemImage: "drop.fill"
            )
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(width: 62)
        .padding(.vertical, 12)
        .background(
            flagged ? Color.red.opacity(0.09) : Color.white.opacity(0.05),
            in: RoundedRectangle(cornerRadius: 14)
        )
    }

    private func durationContext(
        estimated: Double,
        window: Double
    ) -> some View {
        let isShort = window < estimated + 1

        return HStack(alignment: .top, spacing: 11) {
            Image(systemName:
                isShort
                    ? "exclamationmark.triangle.fill"
                    : "clock.fill"
            )
            .foregroundStyle(isShort ? .orange : .aretOrange)

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    isShort
                        ? "Finestra probabilmente troppo breve"
                        : "Verifica anche i tempi di rientro"
                )
                .font(.subheadline.weight(.bold))

                Text(
                    "Percorso tracciato: almeno ~\(String(format: "%.1f", estimated)) ore di movimento stimate, senza soste. La stima può NON comprendere discesa e avvicinamento se assenti dal GPX."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .aretGlassCard(cornerRadius: 19, padding: 13)
    }

    private var reasons: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("PERCHÉ QUESTA VALUTAZIONE")
                .font(.caption.weight(.bold))
                .tracking(0.9)
                .foregroundStyle(.secondary)

            ForEach(
                Array(assessment.reasons.enumerated()),
                id: \.offset
            ) { _, reason in
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(advisoryColor)
                        .font(.caption)
                        .padding(.top, 2)

                    Text(reason)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .aretGlassCard(cornerRadius: 21, padding: 15)
    }
}
