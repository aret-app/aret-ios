import Foundation
import SwiftUI
import UIKit

/// Export an itinerary as a standard GPX file, never uploading it.
/// The temporary file lives inside the app sandbox until explicitly shared.
enum RouteGPXExporter {
    enum ExportError: LocalizedError {
        case missingGeometry
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .missingGeometry:
                return "Questo percorso non contiene abbastanza coordinate GPS."
            case .encodingFailed:
                return "Impossibile preparare il file GPX."
            }
        }
    }

    static func export(_ route: RouteLibraryItem) throws -> URL {
        guard route.coordinates.count > 1 else {
            throw ExportError.missingGeometry
        }

        let escapedName = xmlEscape(route.name)

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 6
        formatter.maximumFractionDigits = 8

        func number(_ value: Double) -> String {
            formatter.string(from: NSNumber(value: value)) ?? "0"
        }

        let points = route.coordinates.map { point in
            let altitudeLine: String
            if let altitude = point.altitude, altitude.isFinite {
                altitudeLine = "<ele>\(number(altitude))</ele>"
            } else {
                altitudeLine = ""
            }

            return """
                  <trkpt lat="\(number(point.latitude))" lon="\(number(point.longitude))">
                    \(altitudeLine)
                  </trkpt>
            """
        }.joined(separator: "\n")

        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="ARET"
             xmlns="http://www.topografix.com/GPX/1/1">
          <metadata>
            <name>\(escapedName)</name>
          </metadata>
          <trk>
            <name>\(escapedName)</name>
            <trkseg>
        \(points)
            </trkseg>
          </trk>
        </gpx>
        """

        guard let data = gpx.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ARET_\(UUID().uuidString).gpx")

        try PrivateStorage.writeProtected(data, to: url)
        return url
    }

    private static func xmlEscape(_ input: String) -> String {
        input
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

struct ExportedRouteFile: Identifiable {
    let id = UUID()
    let url: URL
}

struct ARETGPXShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
