import Foundation
import ActivityKit

struct ARETTrackingAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var distanceMeters: Double
        var ascentMeters: Double
        var altitudeMeters: Double?
        var isTracking: Bool
    }

    var activityName: String
    var startedAt: Date
}
