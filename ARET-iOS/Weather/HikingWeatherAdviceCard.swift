import SwiftUI

/// Conservative forecast interpretation for hiking.
/// This is NOT a safety certification, hazard bulletin or go/no-go order.
struct HikingWeatherAssessment {
    enum Guidance {
        case relativelyFavorable
        case caution
        case considerPostponing
        case insufficientData

        var title: String {
            switch self {
            case .relativelyFavorable:
                return "Condizioni relativamente favorevoli"
            case .caution:
                return "Serve prudenza"
            case .considerPostponing:
                return "Meglio valutare un rinvio"
            case .insufficientData:
                return "Dati insufficienti"
            }
        }

        var symbol: String {
            switch self {
            case .relativelyFavorable:
                return "checkmark.circle.fill"
            case .caution:
                return "exclamationmark.triangle.fill"
            case .considerPostponing:
                return "xmark.octagon.fill"
            case .insufficientData:
                return "questionmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .relativelyFavorable:
                return .green
            case .caution:
                return .orange
            case .considerPostponing:
                return .red
            case .insufficientData:
                return .secondary
            }
        }
    }

    let guidance: Guidance
    let reasons: [String]
    let freezingLevelMeters: Double?
    let windAloftKPH: Double?
    let windAloftHeightMeters: Double?

    static func evaluate(
        hours: [HourlyWeather],
        window: WeatherWindow,
        maximumRouteAltitudeMeters: Int
    ) -> HikingWeatherAssessment {
        let daylight = hours.filter { hour in
            if let isDaylight = hour.isDaylight {
                return isDaylight
            }
            guard let time = hour.hour else { return false }
            return time >= 6 && time <= 19
        }

        guard !daylight.isEmpty else {
            return HikingWeatherAssessment(
                guidance: .insufficientData,
                reasons: [
                    "Previsioni orarie diurne non disponibili per questa data."
                ],
                freezingLevelMeters: nil,
                windAloftKPH: nil,
                windAloftHeightMeters: nil
            )
        }

        // Analyze the proposed window when one exists; never infer a
        // safe departure time from a single isolated acceptable hour.
        let inWindow: [HourlyWeather]
        if let start = window.startTime,
           let end = window.endTime,
           window.quality != .noClearWindow {
            inWindow = daylight.filter {
                $0.timeLabel >= start && $0.timeLabel < end
            }
        } else {
            inWindow = daylight
        }

        let relevant = inWindow.isEmpty ? daylight : inWindow
        let maxGust = relevant.map(\.windGustKPH).max() ?? 0
        let maxPrecipitation = relevant.map(\.precipitationMM).max() ?? 0
        let maxRainProbability =
            relevant.map(\.precipitationProbability).max() ?? 0
        let lowVisibility = relevant.compactMap(\.visibilityMeters).min()
        let freezing = relevant.compactMap(\.freezingLevelMeters).min()
        let windLevels = relevant.compactMap { hour -> (
            speed: Double,
            altitude: Double
        )? in
            guard
                let speed = hour.windAloftKPH,
                let altitude = hour.windAloftAltitudeMeters
            else {
                return nil
            }
            return (speed, altitude)
        }
        let strongestWind = windLevels.max {
            $0.speed < $1.speed
        }

        var reasons: [String] = []
        var severe = false
        var caution = false

        if relevant.contains(where: { $0.weatherCode >= 95 }) {
            severe = true
            reasons.append("Temporali previsti nelle ore considerate.")
        } else if daylight.contains(where: { $0.weatherCode >= 95 }) {
            caution = true
            reasons.append(
                "Temporali previsti in altre ore della giornata: pianifica anche il rientro."
            )
        }

        if maxGust >= 65 {
            severe = true
            reasons.append(
                "Raffiche a 10 m fino a \(Int(maxGust.rounded())) km/h."
            )
        } else if maxGust >= 40 {
            caution = true
            reasons.append(
                "Raffiche a 10 m fino a \(Int(maxGust.rounded())) km/h."
            )
        }

        if let strongestWind {
            if strongestWind.speed >= 70 {
                severe = true
            } else if strongestWind.speed >= 45 {
                caution = true
            }

            if strongestWind.speed >= 45 {
                reasons.append(
                    "Vento \(Int(strongestWind.speed.rounded())) km/h al livello atmosferico di circa \(Int(strongestWind.altitude.rounded())) m: non è una previsione delle raffiche sulla cresta."
                )
            }
        }

        if maxPrecipitation >= 2.5 || maxRainProbability >= 85 {
            caution = true
            reasons.append(
                "Precipitazioni significative o probabilità elevata nelle ore valutate."
            )
        } else if maxPrecipitation >= 0.5 || maxRainProbability >= 55 {
            caution = true
            reasons.append(
                "Possibili precipitazioni durante l'escursione."
            )
        }

        if let visibility = lowVisibility {
            if visibility < 1_000 {
                severe = true
                reasons.append("Visibilità prevista inferiore a 1 km.")
            } else if visibility < 4_000 {
                caution = true
                reasons.append("Visibilità prevista ridotta.")
            }
        }

        if relevant.contains(where: {
            (71...77).contains($0.weatherCode) ||
                (85...86).contains($0.weatherCode)
        }) {
            caution = true
            reasons.append("Precipitazioni nevose possibili.")
        }

        if let freezing,
           maximumRouteAltitudeMeters > 0,
           freezing <= Double(maximumRouteAltitudeMeters + 250) {
            caution = true
            reasons.append(
                "Zero termico circa \(Int(freezing.rounded())) m, vicino o sotto la quota massima: attenzione a gelo e possibile ghiaccio. Non indica da solo il limite neve."
            )
        }

        let guidance: Guidance
        if severe {
            guidance = .considerPostponing
        } else if window.quality == .noClearWindow {
            guidance = .caution
            reasons.append(
                "Non emerge una finestra continua di almeno due ore adatta alla partenza."
            )
        } else if caution || window.quality == .mixed {
            guidance = .caution
        } else {
            guidance = .relativelyFavorable
            reasons.append(
                "Nelle ore proposte non emergono criticità importanti dai soli parametri disponibili."
            )
        }

        if let start = window.startTime,
           let end = window.endTime,
           let first = Int(start.prefix(2)),
           let last = Int(end.prefix(2)),
           last - first < 4,
           guidance == .relativelyFavorable {
            // An encouraging 2–3 h slot is not enough for many hikes.
            reasons.append(
                "La finestra è breve: verifica che copra salita e rientro."
            )
            return HikingWeatherAssessment(
                guidance: .caution,
                reasons: reasons,
                freezingLevelMeters: freezing,
                windAloftKPH: strongestWind?.speed,
                windAloftHeightMeters: strongestWind?.altitude
            )
        }

        return HikingWeatherAssessment(
            guidance: guidance,
            reasons: Array(reasons.prefix(5)),
            freezingLevelMeters: freezing,
            windAloftKPH: strongestWind?.speed,
            windAloftHeightMeters: strongestWind?.altitude
        )
    }
}

struct HikingWeatherAdviceCard: View {
    let hours: [HourlyWeather]
    let window: WeatherWindow
    let maximumRouteAltitudeMeters: Int

    private var assessment: HikingWeatherAssessment {
        HikingWeatherAssessment.evaluate(
            hours: hours,
            window: window,
            maximumRouteAltitudeMeters: maximumRouteAltitudeMeters
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: assessment.guidance.symbol)
                    .foregroundStyle(assessment.guidance.color)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("VALUTAZIONE METEO ARET")
                        .font(.caption2.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)

                    Text(assessment.guidance.title)
                        .font(.headline)
                }

                Spacer()
            }

            if let freezing = assessment.freezingLevelMeters {
                metric(
                    icon: "snowflake",
                    title: "Zero termico previsto",
                    value: "\(Int(freezing.rounded())) m"
                )
            }

            if let wind = assessment.windAloftKPH,
               let altitude = assessment.windAloftHeightMeters {
                metric(
                    icon: "wind",
                    title: "Vento al livello atmosferico ≈\(Int(altitude.rounded())) m",
                    value: "\(Int(wind.rounded())) km/h"
                )
            }

            ForEach(assessment.reasons, id: \.self) { reason in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .padding(.top, 6)
                        .foregroundStyle(assessment.guidance.color)

                    Text(reason)
                        .font(.subheadline)
                        .foregroundStyle(.primary.opacity(0.85))
                }
            }

            Text(
                "Indicazione automatica, non un via libera: verifica durata e rientro, bollettini ufficiali, condizioni del sentiero e osservazioni sul posto. Vento e quota sono stime modellistiche."
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .aretGlassCard(cornerRadius: 24, padding: 16)
    }

    private func metric(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(.aretOrange)
                .frame(width: 20)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }
}
