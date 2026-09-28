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
        switch weatherCode {
        case 0: return "sun.max.fill"
        case 1...3: return "cloud.sun.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}

actor FieldWeatherService {
    static let shared = FieldWeatherService()

    func currentWeather(at location: CLLocation) async throws -> WeatherSnapshot {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(location.coordinate.longitude)),
            URLQueryItem(
                name: "current",
                value: "temperature_2m,precipitation,weather_code,wind_speed_10m,wind_gusts_10m"
            ),
            URLQueryItem(name: "temperature_unit", value: "celsius"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh"),
            URLQueryItem(name: "precipitation_unit", value: "mm"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)

        return WeatherSnapshot(
            temperatureCelsius: decoded.current.temperature2m,
            precipitationMM: decoded.current.precipitation,
            windSpeedKPH: decoded.current.windSpeed10m,
            windGustKPH: decoded.current.windGusts10m,
            weatherCode: decoded.current.weatherCode,
            fetchedAt: Date()
        )
    }
}

private extension FieldWeatherService {
    struct Response: Decodable {
        let current: Current
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
}
