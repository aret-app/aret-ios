import SwiftUI

/// Seven-day forecast selector for the selected route. Tiles show
/// modeled weather windows, not an authorization to undertake the climb.
struct MountainWeatherWeekPicker: View {
    let forecast: WeatherForecast
    let route: RouteLibraryItem
    @Binding var selectedDate: Date

    private var upcomingDays: [DailyWeather] {
        Array(forecast.daily.prefix(7))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.aretOrange)

                Text("SCEGLI IL GIORNO")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)

                Spacer()

                Text("7 giorni")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(upcomingDays) { day in
                        dayTile(day)
                    }
                }
                .padding(.vertical, 4)
            }

            Text(
                "Le fasce orarie mostrano le condizioni meteorologiche previste; non tengono conto automaticamente della durata completa e dei rischi del terreno."
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private func dayTile(_ day: DailyWeather) -> some View {
        let hours = forecast.hourly.filter {
            $0.dateKey == day.rawDate
        }
        let window = WeatherWindowEngine.bestWindow(
            hours: hours,
            routeKind: route.kind
        )
        let isSelected = day.rawDate == selectedDateKey

        return Button {
            if let date = date(from: day.rawDate) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDate = date
                }
            }
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(
                            window.quality == .noClearWindow
                                ? Color.secondary
                                : Color.aretOrange
                        )
                        .frame(width: 6, height: 6)

                    Text(day.dateLabel)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                }

                Image(systemName: day.symbolName)
                    .font(.title2)
                    .foregroundStyle(.aretOrange)
                    .frame(height: 29)

                Text(
                    "\(Int(day.temperatureMinCelsius.rounded()))° / \(Int(day.temperatureMaxCelsius.rounded()))°"
                )
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()

                Text(
                    window.quality == .noClearWindow
                        ? "Nessuna fascia"
                        : window.timeRangeText
                )
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(
                    window.quality == .noClearWindow
                        ? .orange : .secondary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .frame(width: 114)
            .padding(.vertical, 13)
            .background(
                isSelected
                    ? Color.aretOrange.opacity(0.18)
                    : Color.aretSurface,
                in: RoundedRectangle(cornerRadius: 19)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 19)
                    .stroke(
                        isSelected
                            ? Color.aretOrange
                            : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 0.8
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private var selectedDateKey: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone =
            TimeZone(identifier: forecast.timezone) ?? .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }

    private func date(from key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone =
            TimeZone(identifier: forecast.timezone) ?? .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }
}
