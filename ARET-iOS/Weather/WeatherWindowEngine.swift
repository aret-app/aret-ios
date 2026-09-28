import Foundation

struct WeatherWindow: Sendable {
    enum Quality: String, Sendable {
        case favorable = "Favorevole"
        case mixed = "Variabile"
        case noClearWindow = "Nessuna finestra chiara"
    }

    let quality: Quality
    let startTime: String?
    let endTime: String?
    let score: Int
    let reasons: [String]

    var timeRangeText: String {
        guard let startTime, let endTime else {
            return "—"
        }

        return "\(startTime) – \(endTime)"
    }
}

enum WeatherWindowEngine {
    static func bestWindow(
        hours: [HourlyWeather],
        routeKind: RouteKind
    ) -> WeatherWindow {
        let daylightHours = hours.filter {
            guard let hour = $0.hour else { return false }
            return hour >= 5 && hour <= 20
        }

        guard !daylightHours.isEmpty else {
            return WeatherWindow(
                quality: .noClearWindow,
                startTime: nil,
                endTime: nil,
                score: 0,
                reasons: ["Previsioni orarie non disponibili per la giornata scelta."]
            )
        }

        let evaluated = daylightHours.map {
            ($0, evaluate(hour: $0, routeKind: routeKind))
        }

        let acceptable = evaluated.map { item in
            (
                hour: item.0,
                score: item.1.score,
                acceptable: item.1.acceptable,
                reasons: item.1.reasons
            )
        }

        var groups: [[(
            hour: HourlyWeather,
            score: Int,
            acceptable: Bool,
            reasons: [String]
        )]] = []

        var current: [(
            hour: HourlyWeather,
            score: Int,
            acceptable: Bool,
            reasons: [String]
        )] = []

        for item in acceptable {
            if item.acceptable {
                current.append(item)
            } else if !current.isEmpty {
                groups.append(current)
                current = []
            }
        }

        if !current.isEmpty {
            groups.append(current)
        }

        let validGroups = groups.filter { $0.count >= 2 }

        if let best = validGroups.max(by: { groupScore($0) < groupScore($1) }) {
            let averageScore = Int(
                Double(best.map(\.score).reduce(0, +)) /
                Double(best.count)
            )

            let reasons = summarizedReasons(
                from: best.flatMap(\.reasons)
            )

            return WeatherWindow(
                quality: averageScore >= 78 ? .favorable : .mixed,
                startTime: best.first?.hour.timeLabel,
                endTime: endLabel(for: best.last?.hour.timeLabel),
                score: averageScore,
                reasons: reasons
            )
        }

        let bestSingle = acceptable.max { $0.score < $1.score }

        return WeatherWindow(
            quality: .noClearWindow,
            startTime: bestSingle?.hour.timeLabel,
            endTime: bestSingle.flatMap {
                endLabel(for: $0.hour.timeLabel)
            },
            score: bestSingle?.score ?? 0,
            reasons: summarizedReasons(
                from: bestSingle?.reasons ?? [
                    "Le condizioni cambiano troppo durante la giornata."
                ]
            )
        )
    }

    private static func groupScore(
        _ group: [(
            hour: HourlyWeather,
            score: Int,
            acceptable: Bool,
            reasons: [String]
        )]
    ) -> Double {
        let average = Double(group.map(\.score).reduce(0, +)) /
            Double(max(group.count, 1))

        // Prefer both quality and a longer continuous window.
        return average + min(Double(group.count), 8) * 1.5
    }

    private static func evaluate(
        hour: HourlyWeather,
        routeKind: RouteKind
    ) -> (
        score: Int,
        acceptable: Bool,
        reasons: [String]
    ) {
        var score = 100
        var reasons: [String] = []

        let isTechnical =
            routeKind == .sportClimbing ||
            routeKind == .multipitch ||
            routeKind == .alpine ||
            routeKind == .ice ||
            routeKind == .glacier

        if hour.weatherCode >= 95 {
            score -= 100
            reasons.append("temporali previsti")
        }

        switch hour.precipitationProbability {
        case 70...:
            score -= 45
            reasons.append("alta probabilità di precipitazioni")
        case 40..<70:
            score -= 25
            reasons.append("precipitazioni possibili")
        case 20..<40:
            score -= 10
        default:
            break
        }

        if hour.precipitationMM >= 1.0 {
            score -= 35
            reasons.append("precipitazioni significative")
        } else if hour.precipitationMM >= 0.3 {
            score -= 18
            reasons.append("precipitazioni deboli")
        }

        let gustReference = isTechnical ? 35.0 : 45.0

        if hour.windGustKPH >= gustReference + 20 {
            score -= 35
            reasons.append("raffiche forti")
        } else if hour.windGustKPH >= gustReference {
            score -= 22
            reasons.append("raffiche sostenute")
        } else if hour.windGustKPH >= gustReference - 10 {
            score -= 8
        }

        if let visibility = hour.visibilityMeters {
            if visibility < 2_000 {
                score -= 35
                reasons.append("visibilità molto ridotta")
            } else if visibility < 5_000 {
                score -= 15
                reasons.append("visibilità ridotta")
            }
        }

        let clamped = max(0, min(100, score))

        return (
            score: clamped,
            acceptable: clamped >= 60 && hour.weatherCode < 95,
            reasons: reasons
        )
    }

    private static func endLabel(
        for timeLabel: String?
    ) -> String? {
        guard
            let timeLabel,
            timeLabel.count >= 2,
            let hour = Int(timeLabel.prefix(2))
        else {
            return timeLabel
        }

        let nextHour = (hour + 1) % 24
        return String(format: "%02d:00", nextHour)
    }

    private static func summarizedReasons(
        from reasons: [String]
    ) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for reason in reasons where !seen.contains(reason) {
            seen.insert(reason)
            result.append(reason)

            if result.count == 3 {
                break
            }
        }

        if result.isEmpty {
            return [
                "precipitazioni contenute",
                "vento e visibilità relativamente stabili"
            ]
        }

        return result
    }
}
