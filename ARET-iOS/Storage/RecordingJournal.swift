import Foundation

/// One synced append per accepted GPS point. Never truncate an existing recording.
final class RecordingJournal {
    struct Header: Codable {
        let id: UUID
        let name: String
        let startedAt: Date
        var sourceRouteID: String? = nil
    }

    private var appendIsUnsafe = false
    let directory: URL
    var headerURL: URL { directory.appendingPathComponent("recording.json") }
    var pointsURL: URL { directory.appendingPathComponent("points.jsonl") }

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        )[0].appendingPathComponent("ARET/Recording", isDirectory: true)
    }

    var exists: Bool { FileManager.default.fileExists(atPath: directory.path) }

    func begin(name: String, startedAt: Date, sourceRouteID: String? = nil) throws {
        guard !exists else { throw CocoaError(.fileWriteFileExists) }
        try PrivateStorage.prepareDirectory(directory)
        try PrivateStorage.writeProtected(Data(), to: pointsURL)
        try PrivateStorage.writeProtected(
            JSONEncoder().encode(Header(id: UUID(), name: name, startedAt: startedAt, sourceRouteID: sourceRouteID)),
            to: headerURL
        )
    }

    func append(_ point: RecordedTrackPoint) throws {
        try append([point])
    }

    /// Sync once per CoreLocation delivery, including any pending retry points.
    func append(_ points: [RecordedTrackPoint]) throws {
        guard !appendIsUnsafe else { throw CocoaError(.fileWriteUnknown) }
        guard !points.isEmpty else { return }
        var data = Data()
        let encoder = JSONEncoder()
        for point in points {
            data.append(try encoder.encode(point))
            data.append(0x0A)
        }
        let handle = try FileHandle(forWritingTo: pointsURL)
        defer { try? handle.close() }
        let offset = try handle.seekToEnd()
        do {
            try handle.write(contentsOf: data)
            try handle.synchronize()
        } catch {
            do {
                try handle.truncate(atOffset: offset)
                try handle.synchronize()
            } catch {
                // Never append beyond an uncertain/partial rollback.
                appendIsUnsafe = true
            }
            throw error
        }
    }

    /// Preserve even unreadable/empty recordings while freeing the active slot.
    @discardableResult
    func archive() throws -> URL {
        let archives = directory.deletingLastPathComponent()
            .appendingPathComponent("RecordingArchives", isDirectory: true)
        try PrivateStorage.prepareDirectory(archives)
        let destination = archives.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.moveItem(at: directory, to: destination)
        appendIsUnsafe = false
        return destination
    }

    func eraseAll() throws {
        let archives = directory.deletingLastPathComponent()
            .appendingPathComponent("RecordingArchives", isDirectory: true)
        for url in [directory, archives] where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        appendIsUnsafe = false
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
