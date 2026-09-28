import SwiftUI
import MapKit
import CoreLocation

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

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $camera) {
                UserAnnotation()

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
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ARET")
                            .font(.headline.weight(.bold))
                        Text("Every line. One map.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        showEmergency = true
                    } label: {
                        Image(systemName: "sos.circle.fill")
                            .font(.title2)
                    }
                    .tint(.red)
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

                Button {
                    if locationManager.isTracking {
                        locationManager.stopTracking()
                    } else {
                        locationManager.requestPermission()
                        locationManager.startTracking()
                    }
                } label: {
                    Label(
                        locationManager.isTracking ? "Stop activity" : "Start activity",
                        systemImage: locationManager.isTracking ? "stop.fill" : "location.fill"
                    )
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding()
        }
        .sheet(isPresented: $showEmergency) {
            NavigationStack {
                EmergencyView(location: locationManager.location)
            }
            .presentationDetents([.medium, .large])
        }
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
