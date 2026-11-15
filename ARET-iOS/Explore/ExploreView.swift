import SwiftUI
import MapKit
import CoreLocation

private enum MapDisplayStyle:
    String,
    CaseIterable,
    Identifiable {
    case topographic = "Topo Apple"
    case aretTopo = "ARET Sentieri (beta)"
    case hybrid = "Ibrida"
    case satellite = "Satellite"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .topographic:
            return "map"
        case .aretTopo:
            return "point.topleft.down.to.point.bottomright.curvepath"
        case .hybrid:
            return "square.3.layers.3d"
        case .satellite:
            return "globe.europe.africa.fill"
        }
    }
}

struct ExploreView: View {
    @EnvironmentObject private var locationManager:
        LocationManager

    @EnvironmentObject private var activityStore:
        ActivityStore

    @EnvironmentObject private var routeLibrary:
        RouteLibraryStore

    @AppStorage("aret.mapDisplayStyle")
    private var mapDisplayStyleRaw =
        MapDisplayStyle.topographic.rawValue

    @State private var camera:
        MapCameraPosition = .camera(
            MapCamera(
                centerCoordinate:
                    CLLocationCoordinate2D(
                        latitude: 44.05,
                        longitude: 10.20
                    ),
                distance: 14_000,
                heading: 0,
                pitch: 58
            )
        )

    @State private var showEmergency = false
    @State private var weather:
        WeatherSnapshot?

    @State private var completedActivity:
        RecordedActivity?

    @State private var didCenterOnFirstGPSFix = false
    @State private var topoCenterRequest = 0
    @State private var topoFitRequest = 0

    private var mapDisplayStyle:
        MapDisplayStyle {
        MapDisplayStyle(
            rawValue: mapDisplayStyleRaw
        ) ?? .topographic
    }

    private var selectedMapStyle:
        MapStyle {
        switch mapDisplayStyle {
        case .topographic, .aretTopo:
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
            return .imagery(
                elevation: .realistic
            )
        }
    }

    private var activeRouteCoordinates:
        [CLLocationCoordinate2D] {
        routeLibrary.activeRoute?
            .coordinates
            .map(
                .clLocationCoordinate
            ) ?? []
    }

    private var offRouteDistance:
        CLLocationDistance? {
        guard
            locationManager.isTracking,
            let location =
                locationManager.location,
            let route =
                routeLibrary.activeRoute,
            route.coordinates.count >= 2
        else {
            return nil
        }

        return RouteDistanceCalculator
            .distance(
                from: location.coordinate,
                to: route.coordinates
            )
    }

    var body: some View {
        ZStack {
            mapLayer

            LinearGradient(
                colors: [
                    .black.opacity(0.58),
                    .clear,
                    .clear,
                    .black.opacity(0.68)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                Spacer()

                if let distance =
                    offRouteDistance,
                   distance > 75 {
                    offRouteBanner(
                        distance: distance
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }

                if locationManager.isTracking {
                    trackingPanel
                } else {
                    idleRoutePanel
                }
            }
            .padding(.bottom, 8)
        }
        .sheet(
            isPresented: $showEmergency
        ) {
            NavigationStack {
                EmergencyView(
                    location:
                        locationManager
                            .location
                )
            }
            .presentationDetents(
                [.medium, .large]
            )
        }
        .sheet(
            item: $completedActivity
        ) { activity in
            ActivitySummaryView(
                activity: activity
            )
            .environmentObject(
                activityStore
            )
            .environmentObject(
                routeLibrary
            )
            .interactiveDismissDisabled()
        }
        .task {
            locationManager.requestPermission()
            centerOnFirstGPSFixIfNeeded()
        }
        .onChange(of: locationManager.location?.timestamp) {
            _, _ in
            centerOnFirstGPSFixIfNeeded()
        }
        .task(
            id: weatherRefreshKey
        ) {
            await refreshWeather()
        }
        .onChange(of: mapDisplayStyleRaw) { _, _ in
            if routeLibrary.activeRoute != nil {
                fitCameraToActiveRoute()
            } else {
                centerOnUser()
            }
        }
        .onChange(
            of: routeLibrary
                .activeRoute?
                .id
        ) { _, newRouteID in
            guard newRouteID != nil else {
                return
            }

            fitCameraToActiveRoute()
        }
    }

    @ViewBuilder
    private var mapLayer: some View {
        if mapDisplayStyle == .aretTopo {
            ARETTopoMapView(
                routeID: routeLibrary.activeRoute?.id,
                routeCoordinates: routeLibrary.activeRoute?.coordinates ?? [],
                recordedCoordinates: locationManager.isTracking
                    ? locationManager.recordedLocations.map(\.coordinate)
                    : [],
                userCoordinate: locationManager.location?.coordinate,
                centerRequest: topoCenterRequest,
                fitRequest: topoFitRequest
            )
            .overlay(alignment: .trailing) {
                mapControls
                    .padding(.trailing, 15)
                    .offset(y: -30)
            }
            .overlay(alignment: .bottomLeading) {
                Link(
                    "© OpenStreetMap contributors · OpenFreeMap",
                    destination: URL(string: "https://openfreemap.org")!
                )
                .font(.system(size: 9))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.black.opacity(0.65), in: Capsule())
                .padding(.leading, 10)
                .padding(.bottom, 205)
            }
            .ignoresSafeArea()
        } else {
            map
        }
    }

    private var map: some View {
        Map(position: $camera) {
            UserAnnotation()

            if activeRouteCoordinates
                .count > 1 {
                MapPolyline(
                    coordinates:
                        activeRouteCoordinates
                )
                .stroke(
                    .black.opacity(0.68),
                    lineWidth: 9
                )

                MapPolyline(
                    coordinates:
                        activeRouteCoordinates
                )
                .stroke(
                    .aretOrange,
                    lineWidth: 5.5
                )
            }

            if
                locationManager.isTracking,
                locationManager
                    .recordedLocations
                    .count > 1 {
                MapPolyline(
                    coordinates:
                        locationManager
                            .recordedLocations
                            .map(.coordinate)
                )
                .stroke(
                    .white.opacity(0.92),
                    lineWidth: 3.5
                )
            }
        }
        .mapStyle(selectedMapStyle)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .overlay(
            alignment: .trailing
        ) {
            mapControls
                .padding(.trailing, 15)
                .offset(y: -30)
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            ARETWordmark()

            Spacer()

            if let weather {
                HStack(spacing: 6) {
                    Image(
                        systemName:
                            weather.symbolName
                    )

                    Text(
                        "\(Int(weather.temperatureCelsius.rounded()))°"
                    )
                    .monospacedDigit()

                    Text(
                        "\(Int(weather.windSpeedKPH.rounded()))"
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    Image(
                        systemName: "wind"
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
                .font(
                    .caption
                    .weight(.semibold)
                )
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background(
                    .ultraThinMaterial,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(
                            Color.white
                                .opacity(0.10),
                            lineWidth: 0.8
                        )
                }
            }

            Button {
                showEmergency = true
            } label: {
                Image(
                    systemName:
                        "sos.circle.fill"
                )
                .font(.title2)
                .frame(
                    width: 42,
                    height: 42
                )
                .background(
                    .ultraThinMaterial,
                    in: Circle()
                )
            }
            .tint(.red)
            .accessibilityLabel(
                "Emergenza"
            )
        }
    }

    private var mapControls: some View {
        VStack(spacing: 10) {
            Button {
                centerOnUser()
            } label: {
                floatingControl(
                    icon:
                        "location.north.fill"
                )
            }
            .accessibilityLabel(
                "Centra sulla mia posizione"
            )

            Menu {
                ForEach(
                    MapDisplayStyle
                        .allCases
                ) { style in
                    Button {
                        mapDisplayStyleRaw =
                            style.rawValue
                    } label: {
                        Label(
                            style.rawValue,
                            systemImage:
                                style ==
                                mapDisplayStyle
                                ? "checkmark"
                                : style.icon
                        )
                    }
                }
            } label: {
                floatingControl(
                    icon:
                        mapDisplayStyle.icon
                )
            }
            .accessibilityLabel(
                "Stile mappa"
            )

            Button {
                if
                    routeLibrary
                        .activeRoute != nil {
                    fitCameraToActiveRoute()
                } else {
                    centerOnUser()
                }
            } label: {
                floatingControl(
                    icon:
                        "view.3d"
                )
            }
            .accessibilityLabel(
                "Vista percorso"
            )
        }
        .tint(.white)
    }

    private func floatingControl(
        icon: String
    ) -> some View {
        Image(systemName: icon)
            .font(
                .system(
                    size: 16,
                    weight: .semibold
                )
            )
            .frame(
                width: 44,
                height: 44
            )
            .background(
                Color.black.opacity(0.64),
                in: Circle()
            )
            .overlay {
                Circle()
                    .stroke(
                        Color.white
                            .opacity(0.13),
                        lineWidth: 0.8
                    )
            }
            .shadow(
                color:
                    .black.opacity(0.28),
                radius: 8,
                y: 4
            )
    }

    @ViewBuilder
    private var idleRoutePanel:
        some View {
        if let route =
            routeLibrary.activeRoute {
            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                HStack(
                    alignment: .top,
                    spacing: 12
                ) {
                    ZStack {
                        RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                        .fill(
                            Color.aretOrange
                                .opacity(0.14)
                        )

                        Image(
                            systemName:
                                route.kind ==
                                .hiking
                                ? "figure.hiking"
                                : "mountain.2.fill"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            .aretOrange
                        )
                    }
                    .frame(
                        width: 50,
                        height: 50
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {
                        Text(route.name)
                            .font(
                                .title3
                                .weight(.bold)
                            )
                            .lineLimit(1)

                        Text(route.subtitle)
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        routeLibrary
                            .clearSelection()
                    } label: {
                        Image(
                            systemName:
                                "xmark.circle.fill"
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }

                HStack(spacing: 0) {
                    routeMetric(
                        value: String(
                            format: "%.1f",
                            route
                                .distanceKilometers
                        ),
                        unit: "km",
                        title: "Distanza"
                    )

                    divider

                    routeMetric(
                        value:
                            "+\(route.ascentMeters)",
                        unit: "m",
                        title: "D+"
                    )

                    divider

                    routeMetric(
                        value:
                            "\(route.maximumAltitudeMeters)",
                        unit: "m",
                        title: "Quota max"
                    )
                }

                if let weather {
                    HStack(spacing: 10) {
                        Image(
                            systemName:
                                weather.symbolName
                        )
                        .font(.title3)
                        .foregroundStyle(
                            .aretOrange
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 2
                        ) {
                            Text(
                                weather
                                    .conditionName
                            )
                            .font(
                                .subheadline
                                .weight(.semibold)
                            )

                            Text(
                                "\(Int(weather.temperatureCelsius.rounded()))° · vento \(Int(weather.windSpeedKPH.rounded())) km/h · raffiche \(Int(weather.windGustKPH.rounded())) km/h"
                            )
                            .font(.caption2)
                            .foregroundStyle(
                                .secondary
                            )
                        }

                        Spacer()
                    }
                }

                Button {
                    startTracking()
                } label: {
                    HStack {
                        Image(
                            systemName:
                                "play.fill"
                        )

                        Text("Avvia attività")
                            .font(
                                .headline
                            )

                        Spacer()

                        Image(
                            systemName:
                                "arrow.right"
                        )
                    }
                    .padding(.horizontal, 4)
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )
                .tint(.aretOrange)
                .controlSize(.large)
            }
            .aretGlassCard(
                cornerRadius: 28,
                padding: 16
            )
            .padding(.horizontal, 14)
        } else {
            HStack(spacing: 14) {
                ARETMark(size: 46)

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text(
                        "Esplora. Pianifica. Parti."
                    )
                    .font(
                        .headline
                        .weight(.bold)
                    )

                    Text(
                        "Seleziona un itinerario oppure registra un’attività libera."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }

                Spacer()

                Button {
                    startTracking()
                } label: {
                    Image(
                        systemName:
                            "play.fill"
                    )
                    .font(.headline)
                    .frame(
                        width: 48,
                        height: 48
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )
                .tint(.aretOrange)
                .clipShape(Circle())
            }
            .aretGlassCard(
                cornerRadius: 26,
                padding: 14
            )
            .padding(.horizontal, 14)
        }
    }

    private var trackingPanel:
        some View {
        TimelineView(
            .periodic(
                from: .now,
                by: 1
            )
        ) { context in
            let elapsed = max(
                0,
                context.date
                    .timeIntervalSince(
                        locationManager
                            .trackingStartedAt ??
                        context.date
                    )
            )

            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                HStack {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(
                                .aretOrange
                            )
                            .frame(
                                width: 8,
                                height: 8
                            )

                        Text(
                            "REGISTRAZIONE ATTIVA"
                        )
                        .font(
                            .caption2
                            .weight(.bold)
                        )
                        .tracking(1.2)
                    }
                    .foregroundStyle(
                        .aretOrange
                    )

                    Spacer()

                    Text(
                        formatDuration(
                            elapsed
                        )
                    )
                    .font(
                        .title3
                        .weight(.semibold)
                        .monospacedDigit()
                    )
                }

                HStack(spacing: 8) {
                    liveMetric(
                        value: String(
                            format: "%.2f",
                            locationManager
                                .distanceMeters /
                            1000
                        ),
                        unit: "km",
                        label: "Distanza"
                    )

                    liveMetric(
                        value: String(
                            format: "%.0f",
                            locationManager
                                .positiveElevationMeters
                        ),
                        unit: "m",
                        label: "D+"
                    )

                    liveMetric(
                        value:
                            locationManager
                                .location
                                .map {
                                    String(
                                        format:
                                            "%.0f",
                                        $0.altitude
                                    )
                                } ?? "—",
                        unit: "m",
                        label: "Quota"
                    )

                    liveMetric(
                        value: String(
                            format: "%.1f",
                            locationManager
                                .currentSpeedMPS *
                            3.6
                        ),
                        unit: "km/h",
                        label: "Vel."
                    )
                }

                if let route =
                    routeLibrary.activeRoute {
                    HStack(spacing: 8) {
                        Image(
                            systemName:
                                "location.north.fill"
                        )
                        .foregroundStyle(
                            .aretOrange
                        )

                        Text(route.name)
                            .font(
                                .caption
                                .weight(.semibold)
                            )
                            .lineLimit(1)

                        Spacer()

                        if let distance =
                            offRouteDistance {
                            Text(
                                distance <= 75
                                ? "Sulla traccia"
                                : formattedRouteDistance(
                                    distance
                                )
                            )
                            .font(.caption2)
                            .foregroundStyle(
                                distance <= 75
                                ? .green
                                : .orange
                            )
                        }
                    }
                }

                Button(
                    role: .destructive
                ) {
                    stopTracking()
                } label: {
                    Label(
                        "Termina attività",
                        systemImage:
                            "stop.fill"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )
                .tint(
                    Color.red.opacity(0.88)
                )
            }
            .aretGlassCard(
                cornerRadius: 28,
                padding: 16
            )
            .padding(.horizontal, 14)
        }
    }

    private func routeMetric(
        value: String,
        unit: String,
        title: String
    ) -> some View {
        VStack(spacing: 2) {
            HStack(
                alignment: .firstTextBaseline,
                spacing: 2
            ) {
                Text(value)
                    .font(
                        .headline
                        .monospacedDigit()
                    )

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
        .frame(
            maxWidth: .infinity
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(
                Color.white.opacity(0.10)
            )
            .frame(
                width: 1,
                height: 32
            )
    }

    private func liveMetric(
        value: String,
        unit: String,
        label: String
    ) -> some View {
        VStack(spacing: 2) {
            HStack(
                alignment:
                    .firstTextBaseline,
                spacing: 2
            ) {
                Text(value)
                    .font(
                        .subheadline
                        .weight(.semibold)
                        .monospacedDigit()
                    )

                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(
                        .secondary
                    )
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(
                    .secondary
                )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(.vertical, 8)
        .background(
            Color.white.opacity(0.055),
            in: RoundedRectangle(
                cornerRadius: 13,
                style: .continuous
            )
        )
    }

    private func offRouteBanner(
        distance:
            CLLocationDistance
    ) -> some View {
        HStack(spacing: 9) {
            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.orange)

            Text(
                "Fuori traccia · \(formattedRouteDistance(distance))"
            )
            .font(
                .caption
                .weight(.semibold)
            )

            Spacer()
        }
        .aretGlassCard(
            cornerRadius: 18,
            padding: 11
        )
    }

    private var weatherRefreshKey:
        String {
        guard let location =
                locationManager.location
        else {
            return "none"
        }

        let lat =
            (
                location
                    .coordinate
                    .latitude * 100
            ).rounded() / 100

        let lon =
            (
                location
                    .coordinate
                    .longitude * 100
            ).rounded() / 100

        return "\(lat),\(lon)"
    }

    private func startTracking() {
        locationManager
            .requestPermission()

        let activityName =
            routeLibrary
                .activeRoute?
                .name ??
            "Attività libera"

        locationManager
            .startTracking(
                name: activityName,
                sourceRouteID: routeLibrary.activeRoute?.id
            )
    }

    private func stopTracking() {
        let activityName =
            routeLibrary
                .activeRoute?
                .name ??
            "Attività libera"

        if let activity =
            locationManager.stopTracking(
                name: activityName,
                sourceRouteID:
                    routeLibrary
                        .activeRoute?
                        .id
            ) {
            if activityStore.add(activity) {
                locationManager.confirmRecordingSaved()
                completedActivity = activity
            } else {
                locationManager.recordingError = "Attività non salvata. Registrazione conservata per il recupero."
            }
        }
    }

    private func centerOnFirstGPSFixIfNeeded() {
        guard
            !didCenterOnFirstGPSFix,
            routeLibrary.activeRoute == nil,
            locationManager.location != nil
        else {
            return
        }

        didCenterOnFirstGPSFix = true
        centerOnUser()
    }

    private func centerOnUser() {
        guard let location =
                locationManager.location
        else {
            locationManager
                .requestPermission()
            return
        }

        if mapDisplayStyle == .aretTopo {
            topoCenterRequest += 1
            return
        }

        let heading =
            location.course >= 0
            ? location.course
            : 0

        withAnimation(
            .easeInOut(
                duration: 0.35
            )
        ) {
            camera = .camera(
                MapCamera(
                    centerCoordinate:
                        location.coordinate,
                    distance: 850,
                    heading: heading,
                    pitch: 58
                )
            )
        }
    }

    private func refreshWeather()
        async {
        guard let location =
                locationManager.location
        else {
            return
        }

        do {
            weather =
                try await
                FieldWeatherService
                    .shared
                    .currentWeather(
                        at: location
                    )
        } catch {
            weather = nil
        }
    }

    private func fitCameraToActiveRoute() {
        if mapDisplayStyle == .aretTopo {
            topoFitRequest += 1
            return
        }

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
            points.map(.x).min() ?? 0
        let maxX =
            points.map(.x).max() ?? 0
        let minY =
            points.map(.y).min() ?? 0
        let maxY =
            points.map(.y).max() ?? 0

        var rect = MKMapRect(
            x: minX,
            y: minY,
            width: max(
                maxX - minX,
                1
            ),
            height: max(
                maxY - minY,
                1
            )
        )

        rect = rect.insetBy(
            dx:
                -rect.size.width *
                0.22,
            dy:
                -rect.size.height *
                0.22
        )

        camera = .rect(rect)
    }

    private func formattedRouteDistance(
        _ distance:
            CLLocationDistance
    ) -> String {
        if distance < 1000 {
            return
                "\(Int(distance.rounded())) m"
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

        let hours =
            total / 3600

        let minutes =
            (total % 3600) / 60

        let secs =
            total % 60

        if hours > 0 {
            return String(
                format:
                    "%d:%02d:%02d",
                hours,
                minutes,
                secs
            )
        }

        return String(
            format:
                "%02d:%02d",
            minutes,
            secs
        )
    }
}
