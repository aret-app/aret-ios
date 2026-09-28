import SwiftUI
import CoreLocation
import UIKit

struct EmergencyView: View {
    let location: CLLocation?

    var body: some View {
        List {
            Section("Emergency position") {
                row("Latitude", coordinateText(location?.coordinate.latitude))
                row("Longitude", coordinateText(location?.coordinate.longitude))
                row("Altitude", location.map { "\(Int($0.altitude)) m" } ?? "—")
                row(
                    "GPS accuracy",
                    location.map { "±\(Int(max(0, $0.horizontalAccuracy))) m" } ?? "—"
                )
                row(
                    "Updated",
                    location?.timestamp.formatted(date: .omitted, time: .standard) ?? "—"
                )
            }

            Section {
                Button("Call 112", role: .destructive) {
                    guard let url = URL(string: "tel:112") else { return }
                    UIApplication.shared.open(url)
                }

                if let location {
                    ShareLink(
                        item: "ARET emergency position: \(location.coordinate.latitude), \(location.coordinate.longitude) — altitude \(Int(location.altitude)) m"
                    ) {
                        Label("Share position", systemImage: "square.and.arrow.up")
                    }
                }
            }

            Section {
                Text("ARET does not replace official emergency services, Apple Emergency SOS or satellite emergency features.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Emergency")
    }

    private func coordinateText(_ value: CLLocationDegrees?) -> String {
        guard let value else { return "—" }
        return String(format: "%.6f", value)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}
