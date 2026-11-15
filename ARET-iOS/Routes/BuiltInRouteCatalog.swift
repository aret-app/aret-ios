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
        encodedPolylineBase64: "Y3d1a0dnc3p9QERKUXRAXWxBaUBsQFtWR0JNQ0BLUENCSVBvQFxvQkVfQEBrQkFjQUVLQUZAUENGRUBLXUlLQVVIcUBIS0NDQ0JTXkFLQFNOX0BSVWRAT1dLV0FdQkNHXnNARENIRVxDSEVlQEtAR1pHP0NVP1VTWj9GRUtDS1NPR0FHWElKRkBFTUtFR0BBWUNHRUhJeEBXSEBOSD9JRVU/RVJMVGZAREBCR0t1QEFbTEJUVkBBR01DW0VLUVFVRz9RP0JAQ0BIRkVHSENJQkM/Qj9BQT9OQVhIRj9HW0dFQkA/Q01RY0FhQGFBQmtASkpXakBrQERPQlFDXUJXdUBnQm9AYUBNQEdDUV9AW09LSUtRX0BnQUlLYUBHVUtPS0lRXVVlQE9xQF11QEtZQGFATm9ARU9tQF1xQF9AX0FBUURjQD9dQVdLX0BZX0BJU1NdS0VTQElEVVpfQVJhQFFzQGVAWU1jQEl1QFV7QEtjQD9lQEhpQEBlQEpLSFtgQENIP1BUbEBAWFFwQFF+QENcQlJgQHJARlpCakBHdEBBbkBIckBDWERMSEFAQkFBP0REQUNDQVlJUU9zQEJrQERpQEB3QENJX0BxQE1hQEFRP01OY0BGZ0BIV0JlQEVXS1dJT0U/W19ASVVNUU9hQEtrQElPdUBhQFNTXU9pQXFAR0dFTWFBZUBJQVdVTUVTT2dBV11ZUUl3QX1AWWFAR09DTU1VYUBpQVlrQF1nQFNnQF1xQFFTTV9AZ0B9QE9fQEtlQEtVU21AYUB9QEZJQz9CQkFFSkZcUVxDRkdDT0dDS1dVW0NHP0dMSXRAR1RGUEVOQGhAXk5YTlRQSkBFQU0/Y0BFZ0BAX0BMeUBAW0lZZUB9QHlBYUNnQHNAZUF1QFVDYUBNQUVGTXJAZUBkQWdAXEVSRFA/SkNoQFVOP1JHSz9DR1NFS1FfQF9AR0s/SUJBQUI/QUQ/TkpUS1xBTkdGQFZFTUlFSVdLUUtVWVFLSUtJZ0BGTUhJYkBWSkNKSGZARl5RREA/Q1FTWUFRUUFHTU9PZ0BDVUBJYkBOYEBAUVNfQHtBTVtjQG9Ad0BfQElBbUBXZ0BJYUBXWUVNSV9AQUdDQ0lCRWpAYUBSU1NDYUBZT0FbQldHRUVBRUhJQEV2QG1ART9JSWVAUUBVP0JSV05FREdUSklDR1FiQD9ERUFDaEBKQkE/Q0xBSUFFSUdDSUlDRz9HP0NDQD9HVk5qQFFyQlFoQE9MS0hBSkBHSUxPSENCR05HUEQ/R0JFRD9IRkY/QkJKQ1BAVEpGQ1JBcEBTREBMRUpXXF9ARlNMQUhZSklMVUxHSE1YP0JHUkdMT0ZKU0lJQj9BRkJBREtASUhCQEdAQkU/REBBQEBBQUFCW0JLTElCVV5DQEtYT0RFTm1AcEBBSEU/Q0JJUEVBZUBIY0BHTUldQGVATWlAP1FIYUBERUBqQFRKSD9EWUJDREtGcUFWZUBAZUFOVUBATEhGREJIR0RCP0hHTFtKR0NXQUtFUz9GSENBQEJBP0JGTEBJSFVAS0RNVEU/QEJoQFRARkFEUVBdVEVIR0I/QlpKaEBDYEBMREpSRENIX0F2QEFCQEJGQlpDWEhOQlROR0VQSF5GaEBWUkJiQFRSRFBMXGZAZEBwQlJkQENAW0VhQFFBREJUSmZATFBSVGBARkpUS0pZRGFAQVFJU0FTUUdDQ0RBRkNBRUhKYEBGSkpGYkBkQFxQVFhFRF1AUURpQUFKVm5AbkBGP0hGSD8/SmVARmdAVlc/WUNXQmdBZkBvQGZAQkBFQUJBR0BHSGRATF5GYEBgQFxUYEBqQGhBbkJISGxAaEFIYkBNfkBDYkBEakBAfEBJP0tJX0BtQGdAYUBPQVFGVUd3QERLQkBGbEBkQUBOR0hRP1NGZ0BCP0ZDQkxKbEBwQUZYUnBAVmZAXmxARlRgQHBAVHBAekB6QWBAYAFEUFRaREg/TkhGTFJmQFpuQGhAXE5UUlZIUEBkQExKTEpAWFhKQHxAaEBGQExSZEBcakBWdkF+QExUTG5ATFpISkZYRkhORkxDTEJIV0tPQkdCQEZHSUhCRENDQkNDQkJDQE5CQFBASEhIQExFUkJBP1FOVUFXVU1DQU9BQFJLYEFLVkFwQEtYQkZEQ0E/QkBDQEBWQ2hBWmRARFxQbEBmQGpATnZATWRAYUBKP1RESkhQXlJWSlREUkJkQD9YQ1RAVkZQTE5MWlh0QERaREhQRFZAbEBJekBEUEJsQF5mQExcWEpOVk5QRlpCTlhYekBITGZAYkBQWERAUj9uQGZAWm5ATGJASEpDZEBAXEFMS1JxQHJAP0JOSXZBSWRBaEBWYkBAUmdASUVAQUZERE5EUE5GVEZiQEFCQUFRVUtFQ0BGVkRyQEFKSUNHUVFXS0s/REZaQ0hXS3FATlFIQkRGQ0pCWlw/QkNES0dXRk5CUFpGQEFGR0JXQVBMVEJAQlNKQD9HQUVCTEBSQT9MQ0hDP0BDWUZRSF1oQEFGTkNgQD9SRkpKR0ZZRklGVWBAS14/REJATFlGQ0JAR1RHdEBMWERaP1FCR0E/QklGP0JMQHpCQWxARlxDTkteTWJBWXZATUo/RFZNdkB5QEhTVl9B"
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
