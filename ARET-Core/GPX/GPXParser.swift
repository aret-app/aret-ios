import Foundation

public enum GPXParserError: Error {
    case invalidData
    case emptyTrack
}

public final class GPXParser: NSObject {
    public override init() {
        super.init()
    }

    public func parse(data: Data) throws -> [ARETCoordinate] {
        let delegate = GPXDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate

        guard parser.parse() else {
            throw parser.parserError ?? GPXParserError.invalidData
        }

        guard !delegate.coordinates.isEmpty else {
            throw GPXParserError.emptyTrack
        }

        return delegate.coordinates
    }
}

private final class GPXDelegate: NSObject, XMLParserDelegate {
    var coordinates: [ARETCoordinate] = []

    private var pendingLatitude: Double?
    private var pendingLongitude: Double?
    private var pendingElevation: Double?
    private var currentText = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentText = ""

        guard elementName == "trkpt" || elementName == "rtept" else { return }

        pendingLatitude = attributeDict["lat"].flatMap(Double.init)
        pendingLongitude = attributeDict["lon"].flatMap(Double.init)
        pendingElevation = nil
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "ele" {
            pendingElevation = Double(currentText.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        guard elementName == "trkpt" || elementName == "rtept" else { return }
        guard let latitude = pendingLatitude, let longitude = pendingLongitude else { return }

        coordinates.append(
            ARETCoordinate(
                latitude: latitude,
                longitude: longitude,
                altitude: pendingElevation
            )
        )

        pendingLatitude = nil
        pendingLongitude = nil
        pendingElevation = nil
    }
}
