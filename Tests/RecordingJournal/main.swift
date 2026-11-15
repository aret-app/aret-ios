import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

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
// A separate process is killed after its last successful sync, with no cleanup.
if CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "--crash-writer" {
    let child = RecordingJournal(directory: URL(fileURLWithPath: CommandLine.arguments[2]))
    try child.begin(name: "Crash test", startedAt: Date(timeIntervalSince1970: 0))
    for index in 0..<100 {
        try child.append(RecordedTrackPoint(latitude: 44 + Double(index) / 1_000_000,
                                           timestamp: Date(timeIntervalSince1970: Double(index))))
    }
    try FileHandle.standardOutput.write(contentsOf: Data("ready\n".utf8))
    while true { Thread.sleep(forTimeInterval: 1) }
}
let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
defer { try? FileManager.default.removeItem(at: root) }
try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
let activeDirectory = root.appendingPathComponent("Recording")
let crashDirectory = root.appendingPathComponent("CrashRecording")
let process = Process()
process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
process.arguments = ["--crash-writer", crashDirectory.path]
let pipe = Pipe()
process.standardOutput = pipe
try process.run()
let ready = try pipe.fileHandleForReading.read(upToCount: 6)
check(ready == Data("ready\n".utf8), "child synced before kill")
check(kill(process.processIdentifier, SIGKILL) == 0, "kill writer")
process.waitUntilExit()
let crashRecovered = try RecordingJournal(directory: crashDirectory).read().1
check(crashRecovered.count == 100, "all synced points survive SIGKILL")
check(crashRecovered.last?.timestamp == Date(timeIntervalSince1970: 99), "final synced sample survives")
let journal = RecordingJournal(directory: activeDirectory)
let startedAt = Date(timeIntervalSince1970: 1000)
try journal.begin(name: "Synthetic test", startedAt: startedAt, sourceRouteID: "test-route")
let points = (0..<20_000).map {
    RecordedTrackPoint(latitude: 44 + Double($0) / 1_000_000, timestamp: startedAt.addingTimeInterval(Double($0)))
}
for start in stride(from: 0, to: points.count, by: 10) {
    try journal.append(Array(points[start..<min(start + 10, points.count)]))
}
let reopened = RecordingJournal(directory: activeDirectory)
let (header, recovered) = try reopened.read()
check(header.startedAt == startedAt, "start time")
check(header.sourceRouteID == "test-route", "route context survives restart")
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
let archive = try reopened.archive()
check(!reopened.exists, "archive frees recording slot")
check(try Data(contentsOf: archive.appendingPathComponent("points.jsonl")) == Data("invalid\n".utf8), "archive preserves corrupt original")
try reopened.begin(name: "Next recording", startedAt: startedAt)
check(try reopened.read().1.isEmpty, "empty recording can be read")
// Backward compatibility: headers written by PR #10 had no sourceRouteID.
let oldHeader = "{\"id\":\"\(UUID().uuidString)\",\"name\":\"legacy\",\"startedAt\":0}"
try Data(oldHeader.utf8).write(to: reopened.headerURL)
check(try reopened.read().0.sourceRouteID == nil, "legacy header remains readable")
// An encoding failure must leave existing bytes untouched.
let beforeFailure = try Data(contentsOf: reopened.pointsURL)
do {
    try reopened.append(RecordedTrackPoint(latitude: .infinity, timestamp: startedAt))
    fatalError("non-finite value must fail encoding")
} catch { }
check(try Data(contentsOf: reopened.pointsURL) == beforeFailure, "failed append is non-destructive")
try reopened.append(points[0])
check(try reopened.read().1 == [points[0]], "retry after encoding failure")
try reopened.eraseAll()
check(!reopened.exists, "erase removes active journal")
check(!FileManager.default.fileExists(atPath: archive.path), "erase removes archived GPS too")
try reopened.eraseAll() // idempotent cleanup
print("PASS: SIGKILL recovery, 20,000 points, batch reopen, route context, legacy header, overwrite guard, torn append, identity, non-destructive reads, corruption/archive, encoding failure/retry, privacy erase")
