import SwiftUI
import MapKit
import CoreLocation
import UniformTypeIdentifiers

struct ExploreView: View {
    @EnvironmentObject private var locationManager: LocationManager

    @State private var camera: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 44.05, longitude: 10.20),
            distance: 14_000,
            heading: 0,
            pitch: 62
        )
    )

    @State private var showEmergency = false
    @State private var showGPXImporter = false
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var weather: WeatherSnapshot?
    @State private var weatherError: String?

    private var gpxType: UTType {
        UTType(filenameExtension: "gpx") ?? .xml
    }

    private var offRouteDistance: CLLocationDistance? {
        guard let location = locationManager.location, routeCoordinates.count >= 2 else {
            return nil
        }

        let route = routeCoordinates.map {
            ARETCoordinate(latitude: $0.latitude, longitude: $0.longitude)
        }

        return RouteDistanceCalculator.distance(
            from: location.coordinate,
            to: route
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $camera) {
                UserAnnotation()

                if routeCoordinates.count > 1 {
                    MapPolyline(coordinates: routeCoordinates)
                        .stroke(.white.opacity(0.95), lineWidth: 5)
                }

                if locationManager.recordedLocations.count > 1 {
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
            .ignoresSafeArea()

            VStack(spacing: 12) {
                header

                if let offRouteDistance, offRouteDistance > 75 {
                    Label(
                        "Reference route is \(Int(offRouteDistance)) m away",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    metric(
                        value: String(format: "%.2f", locationManager.distanceMeters / 1000),
                        unit: "km",
                        label: "Distance"
                    )
                    metric(
                        value: String(format: "%.0f", locationManager.positiveElevationMeters),
                        unit: "m",
                        label: "D+"
                    )
                    metric(
                        value: locationManager.location.map { String(format: "%.0f", $0.altitude) } ?? "—",
                        unit: "m",
                        label: "Altitude"
                    )
                }

                if let lastGPX = locationManager.lastRecordedGPXURL {
                    ShareLink(item: lastGPX) {
                        Label("Share last GPX", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 10) {
                    Button {
                        showGPXImporter = true
                    } label: {
                        Label("GPX", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        if locationManager.isTracking {
                            locationManager.stopTracking()
                        } else {
                            locationManager.requestPermission()
                            locationManager.startTracking()
                        }
                    } label: {
                        Label(
                            locationManager.isTracking ? "Stop" : "Start",
                            systemImage: locationManager.isTracking ? "stop.fill" : "location.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
            .padding(16)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .padding()
        }
        .sheet(isPresented: $showEmergency) {
            NavigationStack {
                EmergencyView(location: locationManager.location)
            }
            .presentationDetents([.medium, .large])
        }
        .fileImporter(
            isPresented: $showGPXImporter,
            allowedContentTypes: [gpxType],
            allowsMultipleSelection: false
        ) { result in
            importGPX(result)
        }
        .task(id: weatherRefreshKey) {
            await refreshWeather()
        }
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

    private var weatherRefreshKey: String {
        guard let location = locationManager.location else { return "none" }
        let lat = (location.coordinate.latitude * 100).rounded() / 100
        let lon = (location.coordinate.longitude * 100).rounded() / 100
        return "\(lat),\(lon)"
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

            routeCoordinates = coordinates.map(\.clLocationCoordinate)
            fitCameraToRoute()
        } catch {
            print("ARET GPX import error:", error.localizedDescription)
        }
    }

    private func fitCameraToRoute() {
        guard !routeCoordinates.isEmpty else { return }

        let points = routeCoordinates.map(MKMapPoint.init)
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

    private func metric(value: String, unit: String, label: String) -> some View {
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
