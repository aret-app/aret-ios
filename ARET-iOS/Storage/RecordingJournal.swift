import Foundation

/// One synced append per accepted GPS point. Never truncate an existing recording.
final class RecordingJournal {
    struct Header: Codable {
        let id: UUID
        let name: String
        let startedAt: Date
    }

    let directory: URL
    var headerURL: URL { directory.appendingPathComponent("recording.json") }
    var pointsURL: URL { directory.appendingPathComponent("points.jsonl") }

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        )[0].appendingPathComponent("ARET/Recording", isDirectory: true)
    }

    var exists: Bool { FileManager.default.fileExists(atPath: directory.path) }

    func begin(name: String, startedAt: Date) throws {
        guard !exists else { throw CocoaError(.fileWriteFileExists) }
        try PrivateStorage.prepareDirectory(directory)
        try PrivateStorage.writeProtected(Data(), to: pointsURL)
        try PrivateStorage.writeProtected(
            JSONEncoder().encode(Header(id: UUID(), name: name, startedAt: startedAt)),
            to: headerURL
        )
    }

    func append(_ point: RecordedTrackPoint) throws {
        var data = try JSONEncoder().encode(point)
        data.append(0x0A)
        let handle = try FileHandle(forWritingTo: pointsURL)
        defer { try? handle.close() }
        let offset = try handle.seekToEnd()
        do {
            try handle.write(contentsOf: data)
            try handle.synchronize()
        } catch {
            // Roll back a partial append before a later retry can follow it.
            try? handle.truncate(atOffset: offset)
            throw error
        }
    }

    func read() throws -> (Header, [RecordedTrackPoint]) {
        let header = try JSONDecoder().decode(Header.self, from: Data(contentsOf: headerURL))
        let data = try Data(contentsOf: pointsURL)
        let lines = data.split(separator: 0x0A, omittingEmptySubsequences: false)
        // A killed write may leave a partial final line. Preserve the original file.
        let points = try lines.dropLast().map {
            try JSONDecoder().decode(RecordedTrackPoint.self, from: Data($0))
        }
        return (header, points)
    }

    func remove() throws { try FileManager.default.removeItem(at: directory) }
}
