import Foundation
import CoreLocation

struct WeatherSnapshot: Sendable {
    let temperatureCelsius: Double
    let precipitationMM: Double
    let windSpeedKPH: Double
    let windGustKPH: Double
    let weatherCode: Int
    let fetchedAt: Date

    var symbolName: String {
        WeatherCodePresentation.symbolName(for: weatherCode)
    }

    var conditionName: String {
        WeatherCodePresentation.name(for: weatherCode)
    }
}

struct HourlyWeather: Identifiable, Sendable {
    let id: String
    let rawTime: String
    let timeLabel: String
    let temperatureCelsius: Double
    let precipitationProbability: Int
    let precipitationMM: Double
    let windSpeedKPH: Double
    let windGustKPH: Double
    let weatherCode: Int
    let visibilityMeters: Double?
    let freezingLevelMeters: Double?

    var symbolName: String {
        WeatherCodePresentation.symbolName(for: weatherCode)
    }

    var dateKey: String {
        String(rawTime.prefix(10))
    }

    var hour: Int? {
        guard rawTime.count >= 13 else { return nil }
        let start = rawTime.index(rawTime.startIndex, offsetBy: 11)
        let end = rawTime.index(start, offsetBy: 2)
        return Int(rawTime[start..<end])
    }
}

struct DailyWeather: Identifiable, Sendable {
    let id: String
    let rawDate: String
    let dateLabel: String
    let temperatureMaxCelsius: Double
    let temperatureMinCelsius: Double
    let precipitationProbabilityMax: Int
    let windSpeedMaxKPH: Double
    let windGustMaxKPH: Double
    let weatherCode: Int

    var symbolName: String {
        WeatherCodePresentation.symbolName(for: weatherCode)
    }

    var conditionName: String {
        WeatherCodePresentation.name(for: weatherCode)
    }
}

struct WeatherForecast: Sendable {
    let current: WeatherSnapshot
    let hourly: [HourlyWeather]
    let daily: [DailyWeather]
    let latitude: Double
    let longitude: Double
    let timezone: String
}

enum WeatherCodePresentation {
    static func symbolName(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1...3: return "cloud.sun.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }

    static func name(for code: Int) -> String {
        switch code {
        case 0: return "Sereno"
        case 1: return "Prevalentemente sereno"
        case 2: return "Parzialmente nuvoloso"
        case 3: return "Coperto"
        case 45, 48: return "Nebbia"
        case 51...57: return "Pioviggine"
        case 61...67: return "Pioggia"
        case 71...77: return "Neve"
        case 80...82: return "Rovesci"
        case 85, 86: return "Rovesci di neve"
        case 95...99: return "Temporali"
        default: return "Variabile"
        }
    }
}

actor FieldWeatherService {
    static let shared = FieldWeatherService()

    func currentWeather(at location: CLLocation) async throws -> WeatherSnapshot {
        let result = try await forecast(at: location)
        return result.current
    }

    func forecast(at location: CLLocation) async throws -> WeatherForecast {
        var components = URLComponents(
            string: "https://api.open-meteo.com/v1/forecast"
        )!

        components.queryItems = [
            URLQueryItem(
                name: "latitude",
                value: String(location.coordinate.latitude)
            ),
            URLQueryItem(
                name: "longitude",
                value: String(location.coordinate.longitude)
            ),
            URLQueryItem(
                name: "elevation",
                value: String(Int(location.altitude.rounded()))
            ),
            URLQueryItem(
                name: "current",
                value: "temperature_2m,precipitation,weather_code,wind_speed_10m,wind_gusts_10m"
            ),
            URLQueryItem(
                name: "hourly",
                value: "temperature_2m,precipitation_probability,precipitation,weather_code,wind_speed_10m,wind_gusts_10m"
            ),
            URLQueryItem(
                name: "daily",
                value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,wind_gusts_10m_max"
            ),
            URLQueryItem(name: "forecast_days", value: "16"),
            URLQueryItem(name: "temperature_unit", value: "celsius"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh"),
            URLQueryItem(name: "precipitation_unit", value: "mm"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard
            let http = response as? HTTPURLResponse,
            200..<300 ~= http.statusCode
        else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)

        let current = WeatherSnapshot(
            temperatureCelsius: decoded.current.temperature2m,
            precipitationMM: decoded.current.precipitation,
            windSpeedKPH: decoded.current.windSpeed10m,
            windGustKPH: decoded.current.windGusts10m,
            weatherCode: decoded.current.weatherCode,
            fetchedAt: Date()
        )

        let currentHourPrefix = currentHourKey(
            timezoneIdentifier: decoded.timezone
        )

        var hourly: [HourlyWeather] = []

        let hourlyCount = [
            decoded.hourly.time.count,
            decoded.hourly.temperature2m.count,
            decoded.hourly.precipitationProbability.count,
            decoded.hourly.precipitation.count,
            decoded.hourly.weatherCode.count,
            decoded.hourly.windSpeed10m.count,
            decoded.hourly.windGusts10m.count
        ].min() ?? 0

        for index in 0..<hourlyCount {
            let rawTime = decoded.hourly.time[index]

            if !currentHourPrefix.isEmpty, rawTime < currentHourPrefix {
                continue
            }

            hourly.append(
                HourlyWeather(
                    id: rawTime,
                    rawTime: rawTime,
                    timeLabel: hourLabel(from: rawTime),
                    temperatureCelsius: decoded.hourly.temperature2m[index],
                    precipitationProbability: decoded.hourly.precipitationProbability[index],
                    precipitationMM: decoded.hourly.precipitation[index],
                    windSpeedKPH: decoded.hourly.windSpeed10m[index],
                    windGustKPH: decoded.hourly.windGusts10m[index],
                    weatherCode: decoded.hourly.weatherCode[index],
                    visibilityMeters: nil,
                    freezingLevelMeters: nil
                )
            )
        }

        var daily: [DailyWeather] = []

        let dailyCount = [
            decoded.daily.time.count,
            decoded.daily.weatherCode.count,
            decoded.daily.temperature2mMax.count,
            decoded.daily.temperature2mMin.count,
            decoded.daily.precipitationProbabilityMax.count,
            decoded.daily.windSpeed10mMax.count,
            decoded.daily.windGusts10mMax.count
        ].min() ?? 0

        for index in 0..<dailyCount {
            let rawDate = decoded.daily.time[index]

            daily.append(
                DailyWeather(
                    id: rawDate,
                    rawDate: rawDate,
                    dateLabel: dayLabel(from: rawDate, index: index),
                    temperatureMaxCelsius: decoded.daily.temperature2mMax[index],
                    temperatureMinCelsius: decoded.daily.temperature2mMin[index],
                    precipitationProbabilityMax: decoded.daily.precipitationProbabilityMax[index],
                    windSpeedMaxKPH: decoded.daily.windSpeed10mMax[index],
                    windGustMaxKPH: decoded.daily.windGusts10mMax[index],
                    weatherCode: decoded.daily.weatherCode[index]
                )
            )
        }

        return WeatherForecast(
            current: current,
            hourly: hourly,
            daily: daily,
            latitude: decoded.latitude,
            longitude: decoded.longitude,
            timezone: decoded.timezone
        )
    }

    private func currentHourKey(
        timezoneIdentifier: String
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone =
            TimeZone(identifier: timezoneIdentifier) ??
            .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:00"
        return formatter.string(from: Date())
    }

    private func hourLabel(from raw: String) -> String {
        guard raw.count >= 16 else { return raw }
        let start = raw.index(raw.startIndex, offsetBy: 11)
        let end = raw.index(start, offsetBy: 5)
        return String(raw[start..<end])
    }

    private func dayLabel(
        from raw: String,
        index: Int
    ) -> String {
        if index == 0 { return "Oggi" }
        if index == 1 { return "Domani" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: raw) else {
            return raw
        }

        let output = DateFormatter()
        output.locale = Locale(identifier: "it_IT")
        output.dateFormat = "EEE d"
        return output.string(from: date).capitalized
    }
}

private extension FieldWeatherService {
    struct Response: Decodable {
        let latitude: Double
        let longitude: Double
        let timezone: String
        let current: Current
        let hourly: Hourly
        let daily: Daily
    }

    struct Current: Decodable {
        let temperature2m: Double
        let precipitation: Double
        let weatherCode: Int
        let windSpeed10m: Double
        let windGusts10m: Double

        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case precipitation
            case weatherCode = "weather_code"
            case windSpeed10m = "wind_speed_10m"
            case windGusts10m = "wind_gusts_10m"
        }
    }

    struct Hourly: Decodable {
        let time: [String]
        let temperature2m: [Double]
        let precipitationProbability: [Int]
        let precipitation: [Double]
        let weatherCode: [Int]
        let windSpeed10m: [Double]
        let windGusts10m: [Double]
        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case precipitationProbability = "precipitation_probability"
            case precipitation
            case weatherCode = "weather_code"
            case windSpeed10m = "wind_speed_10m"
            case windGusts10m = "wind_gusts_10m"
        }
    }

    struct Daily: Decodable {
        let time: [String]
        let weatherCode: [Int]
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        let precipitationProbabilityMax: [Int]
        let windSpeed10mMax: [Double]
        let windGusts10mMax: [Double]

        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
            case precipitationProbabilityMax = "precipitation_probability_max"
            case windSpeed10mMax = "wind_speed_10m_max"
            case windGusts10mMax = "wind_gusts_10m_max"
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
