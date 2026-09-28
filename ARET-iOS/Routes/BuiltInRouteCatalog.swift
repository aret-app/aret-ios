import Foundation
import CoreLocation

struct CatalogRoute: Identifiable, Sendable {
    let id: String
    let name: String
    let subtitle: String
    let kind: RouteKind
    let distanceKilometers: Double
    let ascentMeters: Int
    let minimumAltitudeMeters: Int
    let maximumAltitudeMeters: Int
    let encodedPolylineBase64: String

    var coordinates: [CLLocationCoordinate2D] {
        guard
            let data = Data(base64Encoded: encodedPolylineBase64),
            let encoded = String(data: data, encoding: .utf8)
        else {
            return []
        }

        return EncodedPolyline.decode(encoded)
    }
}

enum BuiltInRouteCatalog {
    static let saturdayFieldTest = CatalogRoute(
        id: "field-test-saturday-001",
        name: "Escursione di sabato",
        subtitle: "ARET Field Test 0.1",
        kind: .hiking,
        distanceKilometers: 11.32,
        ascentMeters: 1000,
        minimumAltitudeMeters: 877,
        maximumAltitudeMeters: 1859,
        encodedPolylineBase64: "Y3d1a0dnc3p9QERKb0BiQ2VBZEFVP1ZZbkBfREVvRUVLSWJAVWlAUHNBW14/X0BiQHVAZEBPcUFRZEB3QHBAT2VAS1xPa0BXYkBFaUBnQGZAR3NAX0BiQWFAWEpFZUBuQHZASXlBZEBYUXVAZ0BZP1FKQkdIP01uQEhZdUBjQWFAbUJOdkBjQUhhQD91QHVAZ0JlQWNAUV9AZ0BZdUBlQndAU3dAc0BtQ3lAe0BQb0BFbUFfREJzQU13QHdAcUFfQENfQGBAX0FSb0JlQXVDa0B5Q1ZrQHRAVnhBZ0BuQ2xAYkJFcENKekFOQl9AY0JKbUNzQG9CZEB3Q1FvQGNBd0FbbUFpRX1DZUNzQWdBV2dDYUJnR19NfUFnRURLSkZiQV1xQHdBYkFRdkBCekF6QUNfQ051QW9Ad0FhQ3VEZUF1QHlAV2BDe0FiQT94QWFAY0BNc0BnQVZKYkJZZUJxQVNzQFBXYkJkQGRAU2tAVWFAaUBRZ0FkQVBRU21Ad0JjQG9AeUR7QW9BVT9PfkB1QHVAXWlBS2BBY0F1QFtAVWhAYUBUSlFVYkJFYUBZR1lWTn5DY0BsQVtHSUxPXFNQREJNbkFUckFXfkBxQUxBYkB5QHZBdUBGSl1HREhZTkY/dUBWX0NiRGtARnVCXX1BTnBAZkB7QmhAYUNSSlRUP0dWW0pfQUtUVF9BZkBsQGBAX0F+QGRBRnpAXmNBaEFsQUxmRWBCXGZAeEB2Q2FBVUxiQW5BZEFlQFBhQEFhQWFAT1RSbEBiQnhBX0NKdkF6QW1BXmlBP2VDeEFkQVR+QHZAYkRuRkhiQFFiQkZoQn1BeUFvQkJJSm5AdEF5QWBAZkp6UmpDaEJmQmhAYkhwRWJBcENqQEZIV0tPTk1JSkhMZkFKU05VQWlAZ0B+Q2VAaERmQHZCaEF2QE1kQGFAYEBEfEB2QUZgQ2hBeENyQ0JmQnBAYEF4QGxASnJAYkJ4QHxAWEBuQGZAckB+QUFiQU1gQHFAdkBmQlNkQWhAWHZAZ0BJR0hmQFpOeEBlQFdKdkFvQHlAQmpAV0tjQVhWRFpcZ0BIaEBgQGFASGhAVF9ATGBAPz9McUBWX0BwQHBAQ15Sa0BWYUBgQVxTT2pBUnRARGNASkxGZkVdckJnQGhBbkFnQWBAc0E="
    )

    static let routes: [CatalogRoute] = [
        saturdayFieldTest
    ]
}

private enum EncodedPolyline {
    static func decode(_ encoded: String, precision: Double = 1e5) -> [CLLocationCoordinate2D] {
        let scalars = Array(encoded.unicodeScalars)
        var index = 0
        var latitude = 0
        var longitude = 0
        var result: [CLLocationCoordinate2D] = []

        while index < scalars.count {
            guard let latitudeDelta = decodeValue(scalars, index: &index) else { break }
            guard let longitudeDelta = decodeValue(scalars, index: &index) else { break }

            latitude += latitudeDelta
            longitude += longitudeDelta

            result.append(
                CLLocationCoordinate2D(
                    latitude: Double(latitude) / precision,
                    longitude: Double(longitude) / precision
                )
            )
        }

        return result
    }

    private static func decodeValue(
        _ scalars: [UnicodeScalar],
        index: inout Int
    ) -> Int? {
        var result = 0
        var shift = 0

        while index < scalars.count {
            let byte = Int(scalars[index].value) - 63
            index += 1

            result |= (byte & 0x1F) << shift
            shift += 5

            if byte < 0x20 {
                return (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            }
        }

        return nil
    }
}
