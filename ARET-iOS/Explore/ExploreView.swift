import SwiftUI
import MapKit
import CoreLocation
import UniformTypeIdentifiers

struct ExploreView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var activityStore: ActivityStore
    @EnvironmentObject private var routeLibrary: RouteLibraryStore

    @State private var camera: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 44.05, longitude: 10.20),
            distance: 14_000,
            heading: 0,
            pitch: 55
        )
    )

    @State private var showEmergency = false
    @State private var showGPXImporter = false
    @State private var weather: WeatherSnapshot?
    @State private var weatherError: String?
    @State private var completedActivity: RecordedActivity?

    private var activeRouteCoordinates: [CLLocationCoordinate2D] {
        routeLibrary.activeRoute?.coordinates.map(\.clLocationCoordinate) ?? []
    }

    private var gpxType: UTType {
        UTType(filenameExtension: "gpx") ?? .xml
    }

    private var offRouteDistance: CLLocationDistance? {
        guard locationManager.isTracking,
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
                liveMetrics
                controls
            }
            .padding(16)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
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
        .fileImporter(
            isPresented: $showGPXImporter,
            allowedContentTypes: [gpxType],
            allowsMultipleSelection: false
        ) { result in
            importGPX(result)
        }
        .task {
            locationManager.requestPermission()
        }
        .task(id: weatherRefreshKey) {
            await refreshWeather()
        }
        .onChange(of: routeLibrary.activeRoute?.id) { _, newRouteID in
            guard newRouteID != nil else { return }
            fitCameraToActiveRoute()
        }
    }

    private var map: some View {
        Map(position: $camera) {
            UserAnnotation()

            if activeRouteCoordinates.count > 1 {
                MapPolyline(coordinates: activeRouteCoordinates)
                    .stroke(.white.opacity(0.95), lineWidth: 5)
            }

            if locationManager.isTracking,
               locationManager.recordedLocations.count > 1 {
                MapPolyline(
                    coordinates: locationManager.recordedLocations.map(\.coordinate)
                )
                .stroke(.orange, lineWidth: 4)
            }
        }
        .mapStyle(.standard(elevation: .realistic, emphasis: .muted))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .overlay(alignment: .topTrailing) {
            Button {
                centerOnUser()
            } label: {
                Image(systemName: "location.fill")
                    .font(.title3.weight(.semibold))
                    .frame(width: 46, height: 46)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(radius: 5, y: 2)
            }
            .tint(.primary)
            .padding(.top, 60)
            .padding(.trailing, 16)
            .accessibilityLabel("Vai alla mia posizione")
        }
        .ignoresSafeArea()
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
                    Text("\(Int(weather.temperatureCelsius.rounded()))°")
                        .monospacedDigit()
                    Text("\(Int(weather.windSpeedKPH.rounded())) km/h")
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

                Button {
                    routeLibrary.clearSelection()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Rimuovi percorso dalla mappa")
            }
        } else {
            HStack(spacing: 10) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
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
        if let distance = offRouteDistance, distance > 75 {
            Label(
                "Ti stai allontanando dalla traccia di riferimento · \(formattedRouteDistance(distance))",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var liveMetrics: some View {
        HStack {
            metric(
                value: String(
                    format: "%.2f",
                    locationManager.distanceMeters / 1000
                ),
                unit: "km",
                label: "Distanza"
            )

            metric(
                value: String(
                    format: "%.0f",
                    locationManager.positiveElevationMeters
                ),
                unit: "m",
                label: "D+"
            )

            metric(
                value: locationManager.location.map {
                    String(format: "%.0f", $0.altitude)
                } ?? "—",
                unit: "m",
                label: "Quota"
            )
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                showGPXImporter = true
            } label: {
                Label("Importa GPX", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                toggleTracking()
            } label: {
                Label(
                    locationManager.isTracking ? "Termina" : "Avvia",
                    systemImage: locationManager.isTracking
                    ? "stop.fill"
                    : "location.fill"
                )
                .frame(maxWidth: .infinity)
                .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
    }

    private var weatherRefreshKey: String {
        guard let location = locationManager.location else { return "none" }

        let lat = (location.coordinate.latitude * 100).rounded() / 100
        let lon = (location.coordinate.longitude * 100).rounded() / 100
        return "\(lat),\(lon)"
    }

    private func toggleTracking() {
        if locationManager.isTracking {
            let activityName = routeLibrary.activeRoute?.name ?? "Attività libera"

            if let activity = locationManager.stopTracking(
                name: activityName,
                sourceRouteID: routeLibrary.activeRoute?.id
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
        guard let location = locationManager.location else {
            locationManager.requestPermission()
            return
        }

        let heading = location.course >= 0 ? location.course : 0

        withAnimation(.easeInOut(duration: 0.35)) {
            camera = .camera(
                MapCamera(
                    centerCoordinate: location.coordinate,
                    distance: 900,
                    heading: heading,
                    pitch: 50
                )
            )
        }
    }

    private func refreshWeather() async {
        guard let location = locationManager.location else { return }

        do {
            weather = try await FieldWeatherService.shared.currentWeather(at: location)
            weatherError = nil
        } catch {
            weatherError = error.localizedDescription
        }
    }

    private func importGPX(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }

            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let coordinates = try GPXParser().parse(data: data)

            let stats = routeStats(for: coordinates)

            let route = RouteLibraryItem(
                id: "imported-\(UUID().uuidString)",
                name: url.deletingPathExtension().lastPathComponent,
                subtitle: "GPX importato",
                kind: .hiking,
                distanceKilometers: stats.distance / 1000,
                ascentMeters: Int(stats.ascent.rounded()),
                minimumAltitudeMeters: Int(stats.minimumAltitude.rounded()),
                maximumAltitudeMeters: Int(stats.maximumAltitude.rounded()),
                coordinates: coordinates,
                origin: .importedGPX
            )

            routeLibrary.select(route)
            fitCameraToActiveRoute()
        } catch {
            print("ARET GPX import error:", error.localizedDescription)
        }
    }

    private func routeStats(
        for coordinates: [ARETCoordinate]
    ) -> (
        distance: Double,
        ascent: Double,
        minimumAltitude: Double,
        maximumAltitude: Double
    ) {
        let locations = coordinates.map {
            CLLocation(
                coordinate: $0.clLocationCoordinate,
                altitude: $0.altitude ?? 0,
                horizontalAccuracy: 1,
                verticalAccuracy: 1,
                timestamp: Date()
            )
        }

        let distance = zip(locations, locations.dropFirst())
            .reduce(0.0) { partial, pair in
                partial + pair.0.distance(from: pair.1)
            }

        var ascent = 0.0
        var reference = coordinates.first?.altitude ?? 0

        for coordinate in coordinates.dropFirst() {
            guard let altitude = coordinate.altitude else { continue }
            let delta = altitude - reference

            if abs(delta) >= 2.5 {
                if delta > 0 {
                    ascent += delta
                }
                reference = altitude
            }
        }

        let altitudes = coordinates.compactMap(\.altitude)

        return (
            distance,
            ascent,
            altitudes.min() ?? 0,
            altitudes.max() ?? 0
        )
    }

    private func fitCameraToActiveRoute() {
        let coordinates = activeRouteCoordinates
        guard !coordinates.isEmpty else { return }

        let points = coordinates.map(MKMapPoint.init)
        let minX = points.map(\.x).min() ?? 0
        let maxX = points.map(\.x).max() ?? 0
        let minY = points.map(\.y).min() ?? 0
        let maxY = points.map(\.y).max() ?? 0

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

        return String(format: "%.1f km", distance / 1000)
    }

    private func metric(
        value: String,
        unit: String,
        label: String
    ) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.semibold))
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
