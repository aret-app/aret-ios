import Foundation

// Storage adapter for host tests: intentionally does NOT emulate iOS Data Protection.
enum PrivateStorage {
    static func prepareDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    static func writeProtected(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }
}
// Journal tests isolate disk framing from CoreLocation and the UI.
struct RecordedTrackPoint: Codable, Equatable {
    let latitude: Double
    let timestamp: Date
}

func check(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}
let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
defer { try? FileManager.default.removeItem(at: root) }
let journal = RecordingJournal(directory: root)
let startedAt = Date(timeIntervalSince1970: 1000)
try journal.begin(name: "Synthetic test", startedAt: startedAt)
let points = (0..<20_000).map {
    RecordedTrackPoint(latitude: Double($0) / 1000, timestamp: startedAt.addingTimeInterval(Double($0)))
}
for point in points { try journal.append(point) }
let reopened = RecordingJournal(directory: root)
let (header, recovered) = try reopened.read()
check(header.startedAt == startedAt, "start time")
check(recovered == points, "all long-track points survive reopening")
let original = try Data(contentsOf: journal.pointsURL)
do {
    try reopened.begin(name: "Must not overwrite", startedAt: Date())
    fatalError("begin overwrote incomplete recording")
} catch { }
check(try Data(contentsOf: journal.pointsURL) == original, "begin preserves bytes")
let handle = try FileHandle(forWritingTo: journal.pointsURL)
try handle.seekToEnd()
try handle.write(contentsOf: Data("{\"latitude\":".utf8))
try handle.close()
let damaged = try Data(contentsOf: journal.pointsURL)
let (sameHeader, completePoints) = try reopened.read()
check(sameHeader.id == header.id, "stable recovery identity")
check(completePoints == points, "torn final append retains every complete point")
check(try Data(contentsOf: journal.pointsURL) == damaged, "recovery never edits source")
try Data("invalid\n".utf8).write(to: journal.pointsURL)
do {
    _ = try reopened.read()
    fatalError("interior corruption must be reported")
} catch { }
check(reopened.exists, "corruption retains journal")
try reopened.remove()
check(!reopened.exists, "explicit completion removes journal")
print("PASS: 20,000-point reopen, overwrite guard, torn append, stable ID, non-destructive read, corruption and cleanup")
