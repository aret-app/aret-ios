import SwiftUI
import MapKit
import CoreLocation

private enum MapDisplayStyle: String, CaseIterable, Identifiable {
    case topographic = "Topo"
    case hybrid = "Ibrida"
    case satellite = "Satellite"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .topographic:
            return "map"
        case .hybrid:
            return "square.3.layers.3d"
        case .satellite:
            return "globe.europe.africa.fill"
        }
    }
}

struct ExploreView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var activityStore: ActivityStore
    @EnvironmentObject private var routeLibrary: RouteLibraryStore

    @AppStorage("aret.mapDisplayStyle")
    private var mapDisplayStyleRaw = MapDisplayStyle.topographic.rawValue

    @State private var camera: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(
                latitude: 44.05,
                longitude: 10.20
            ),
            distance: 14_000,
            heading: 0,
            pitch: 55
        )
    )

    @State private var showEmergency = false
    @State private var weather: WeatherSnapshot?
    @State private var weatherError: String?
    @State private var completedActivity: RecordedActivity?

    private var mapDisplayStyle: MapDisplayStyle {
        MapDisplayStyle(rawValue: mapDisplayStyleRaw) ?? .topographic
    }

    private var selectedMapStyle: MapStyle {
        switch mapDisplayStyle {
        case .topographic:
            return .standard(
                elevation: .realistic,
                emphasis: .muted,
                pointsOfInterest: .all,
                showsTraffic: false
            )

        case .hybrid:
            return .hybrid(
                elevation: .realistic,
                pointsOfInterest: .all,
                showsTraffic: false
            )

        case .satellite:
            return .imagery(elevation: .realistic)
        }
    }

    private var activeRouteCoordinates: [CLLocationCoordinate2D] {
        routeLibrary.activeRoute?.coordinates.map(
            \.clLocationCoordinate
        ) ?? []
    }

    private var offRouteDistance: CLLocationDistance? {
        guard
            locationManager.isTracking,
            let location = locationManager.location,
            let route = routeLibrary.activeRoute,
            route.coordinates.count >= 2
        else {
            return nil
        }

        return RouteDistanceCalculator.distance(
            from: location.coordinate,
            to: route.coordinates
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            map

            VStack(spacing: 12) {
                header
                activeRouteSummary
                offRouteWarning

                if locationManager.isTracking {
                    TimelineView(
                        .periodic(from: .now, by: 1)
                    ) { context in
                        liveTrackingDashboard(now: context.date)
                    }
                }

                controls
            }
            .padding(16)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showEmergency) {
            NavigationStack {
                EmergencyView(location: locationManager.location)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $completedActivity) { activity in
            ActivitySummaryView(activity: activity)
                .environmentObject(activityStore)
                .environmentObject(routeLibrary)
                .interactiveDismissDisabled()
        }
        .task {
            locationManager.requestPermission()
        }
        .task(id: weatherRefreshKey) {
            await refreshWeather()
        }
        .onChange(of: routeLibrary.activeRoute?.id) {
            _, newRouteID in

            guard newRouteID != nil else { return }
            fitCameraToActiveRoute()
        }
    }

    private var map: some View {
        Map(position: $camera) {
            UserAnnotation()

            if activeRouteCoordinates.count > 1 {
                MapPolyline(
                    coordinates: activeRouteCoordinates
                )
                .stroke(
                    .white.opacity(0.95),
                    lineWidth: 5
                )
            }

            if locationManager.isTracking,
               locationManager.recordedLocations.count > 1 {
                MapPolyline(
                    coordinates:
                        locationManager.recordedLocations.map(
                            \.coordinate
                        )
                )
                .stroke(.orange, lineWidth: 4)
            }
        }
        .mapStyle(selectedMapStyle)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .overlay(alignment: .topTrailing) {
            VStack(spacing: 10) {
                Button {
                    centerOnUser()
                } label: {
                    controlCircle(
                        icon: "location.fill"
                    )
                }
                .accessibilityLabel(
                    "Vai alla mia posizione"
                )

                Menu {
                    ForEach(MapDisplayStyle.allCases) { style in
                        Button {
                            mapDisplayStyleRaw = style.rawValue
                        } label: {
                            if style == mapDisplayStyle {
                                Label(
                                    style.rawValue,
                                    systemImage: "checkmark"
                                )
                            } else {
                                Label(
                                    style.rawValue,
                                    systemImage: style.icon
                                )
                            }
                        }
                    }
                } label: {
                    controlCircle(
                        icon: mapDisplayStyle.icon
                    )
                }
                .accessibilityLabel(
                    "Scegli visualizzazione mappa"
                )
            }
            .tint(.primary)
            .padding(.top, 60)
            .padding(.trailing, 16)
        }
        .ignoresSafeArea()
    }

    private func controlCircle(
        icon: String
    ) -> some View {
        Image(systemName: icon)
            .font(.title3.weight(.semibold))
            .frame(width: 46, height: 46)
            .background(
                .ultraThinMaterial,
                in: Circle()
            )
            .shadow(radius: 5, y: 2)
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ARET")
                    .font(.headline.weight(.bold))

                Text("Every line. One map.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let weather {
                HStack(spacing: 6) {
                    Image(systemName: weather.symbolName)

                    Text(
                        "\(Int(weather.temperatureCelsius.rounded()))°"
                    )
                    .monospacedDigit()

                    Text(
                        "\(Int(weather.windSpeedKPH.rounded())) km/h"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .font(.caption.weight(.semibold))
            }

            Button {
                showEmergency = true
            } label: {
                Image(systemName: "sos.circle.fill")
                    .font(.title2)
            }
            .tint(.red)
        }
    }

    @ViewBuilder
    private var activeRouteSummary: some View {
        if let route = routeLibrary.activeRoute {
            HStack(spacing: 10) {
                Image(
                    systemName: route.kind == .hiking
                    ? "figure.hiking"
                    : "mountain.2.fill"
                )
                .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(route.name)
                        .font(.subheadline.weight(.semibold))

                    Text(
                        "\(route.distanceKilometers, specifier: "%.1f") km · +\(route.ascentMeters) m · max \(route.maximumAltitudeMeters) m"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if !locationManager.isTracking {
                    Button {
                        routeLibrary.clearSelection()
                    } label: {
                        Image(
                            systemName: "xmark.circle.fill"
                        )
                        .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(
                        "Rimuovi percorso dalla mappa"
                    )
                }
            }
        } else if !locationManager.isTracking {
            HStack(spacing: 10) {
                Image(
                    systemName:
                        "point.topleft.down.to.point.bottomright.curvepath"
                )
                .foregroundStyle(.secondary)

                Text("Nessun percorso selezionato")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var offRouteWarning: some View {
        if let distance = offRouteDistance,
           distance > 75 {
            Label(
                "Ti stai allontanando dalla traccia di riferimento · \(formattedRouteDistance(distance))",
                systemImage:
                    "exclamationmark.triangle.fill"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(.orange)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }

    private func liveTrackingDashboard(
        now: Date
    ) -> some View {
        let elapsed = max(
            0,
            now.timeIntervalSince(
                locationManager.trackingStartedAt ?? now
            )
        )

        let averageSpeedKPH = elapsed > 0
            ? (
                locationManager.distanceMeters /
                elapsed
            ) * 3.6
            : 0

        let altitude = locationManager.location?.altitude
        let accuracy =
            locationManager.location?.horizontalAccuracy

        return LazyVGrid(
            columns: Array(
                repeating: GridItem(
                    .flexible(),
                    spacing: 8
                ),
                count: 3
            ),
            spacing: 10
        ) {
            liveMetric(
                value: formatDuration(elapsed),
                unit: "",
                label: "Durata"
            )

            liveMetric(
                value: String(
                    format: "%.2f",
                    locationManager.distanceMeters / 1000
                ),
                unit: "km",
                label: "Distanza"
            )

            liveMetric(
                value: "\(locationManager.recordedLocations.count)",
                unit: "",
                label: "Punti GPS"
            )

            liveMetric(
                value: String(
                    format: "%.0f",
                    locationManager.positiveElevationMeters
                ),
                unit: "m",
                label: "D+"
            )

            liveMetric(
                value: String(
                    format: "%.0f",
                    locationManager.negativeElevationMeters
                ),
                unit: "m",
                label: "D−"
            )

            liveMetric(
                value: altitude.map {
                    String(format: "%.0f", $0)
                } ?? "—",
                unit: "m",
                label: "Quota"
            )

            liveMetric(
                value: String(
                    format: "%.1f",
                    locationManager.currentSpeedMPS * 3.6
                ),
                unit: "km/h",
                label: "Velocità"
            )

            liveMetric(
                value: String(
                    format: "%.1f",
                    averageSpeedKPH
                ),
                unit: "km/h",
                label: "Media"
            )

            liveMetric(
                value: accuracy.flatMap {
                    $0 >= 0 ? String(
                        format: "%.0f",
                        $0
                    ) : nil
                } ?? "—",
                unit: "m",
                label: "Precisione GPS"
            )
        }
    }

    private func liveMetric(
        value: String,
        unit: String,
        label: String
    ) -> some View {
        VStack(spacing: 3) {
            HStack(
                alignment: .firstTextBaseline,
                spacing: 2
            ) {
                Text(value)
                    .font(
                        .subheadline.weight(.semibold)
                    )
                    .monospacedDigit()

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(
            .thinMaterial,
            in: RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
        )
    }

    private var controls: some View {
        Button {
            toggleTracking()
        } label: {
            Label(
                locationManager.isTracking
                ? "Termina attività"
                : "Avvia",
                systemImage: locationManager.isTracking
                ? "stop.fill"
                : "location.fill"
            )
            .frame(maxWidth: .infinity)
            .font(.headline)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
        .controlSize(.large)
    }

    private var weatherRefreshKey: String {
        guard let location = locationManager.location else {
            return "none"
        }

        let lat =
            (
                location.coordinate.latitude *
                100
            ).rounded() / 100

        let lon =
            (
                location.coordinate.longitude *
                100
            ).rounded() / 100

        return "\(lat),\(lon)"
    }

    private func toggleTracking() {
        if locationManager.isTracking {
            let activityName =
                routeLibrary.activeRoute?.name ??
                "Attività libera"

            if let activity =
                locationManager.stopTracking(
                    name: activityName,
                    sourceRouteID:
                        routeLibrary.activeRoute?.id
                ) {
                activityStore.add(activity)
                completedActivity = activity
            }
        } else {
            locationManager.requestPermission()
            locationManager.startTracking()
        }
    }

    private func centerOnUser() {
        guard let location =
                locationManager.location
        else {
            locationManager.requestPermission()
            return
        }

        let heading =
            location.course >= 0
            ? location.course
            : 0

        withAnimation(
            .easeInOut(duration: 0.35)
        ) {
            camera = .camera(
                MapCamera(
                    centerCoordinate:
                        location.coordinate,
                    distance: 900,
                    heading: heading,
                    pitch: 50
                )
            )
        }
    }

    private func refreshWeather() async {
        guard let location =
                locationManager.location
        else {
            return
        }

        do {
            weather =
                try await
                FieldWeatherService.shared
                    .currentWeather(at: location)

            weatherError = nil
        } catch {
            weatherError =
                error.localizedDescription
        }
    }

    private func fitCameraToActiveRoute() {
        let coordinates =
            activeRouteCoordinates

        guard !coordinates.isEmpty else {
            return
        }

        let points =
            coordinates.map(
                MKMapPoint.init
            )

        let minX =
            points.map(\.x).min() ?? 0
        let maxX =
            points.map(\.x).max() ?? 0
        let minY =
            points.map(\.y).min() ?? 0
        let maxY =
            points.map(\.y).max() ?? 0

        var rect = MKMapRect(
            x: minX,
            y: minY,
            width: max(maxX - minX, 1),
            height: max(maxY - minY, 1)
        )

        rect = rect.insetBy(
            dx: -rect.size.width * 0.18,
            dy: -rect.size.height * 0.18
        )

        camera = .rect(rect)
    }

    private func formattedRouteDistance(
        _ distance: CLLocationDistance
    ) -> String {
        if distance < 1000 {
            return "\(Int(distance.rounded())) m"
        }

        return String(
            format: "%.1f km",
            distance / 1000
        )
    }

    private func formatDuration(
        _ seconds: TimeInterval
    ) -> String {
        let total =
            max(
                0,
                Int(seconds.rounded())
            )

        let hours = total / 3600
        let minutes =
            (total % 3600) / 60
        let secs = total % 60

        if hours > 0 {
            return String(
                format: "%d:%02d:%02d",
                hours,
                minutes,
                secs
            )
        }

        return String(
            format: "%02d:%02d",
            minutes,
            secs
        )
    }
}
