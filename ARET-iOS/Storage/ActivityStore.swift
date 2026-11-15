import Foundation
import Combine

@MainActor
final class ActivityStore: ObservableObject {
    @Published private(set) var activities: [RecordedActivity] = []

    private let storeURL: URL

    init(storageDirectory: URL? = nil) {
        let directory = storageDirectory ?? FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        .appendingPathComponent("ARET", isDirectory: true)

        try? PrivateStorage.prepareDirectory(directory)

        storeURL = directory.appendingPathComponent("activities.json")
        try? PrivateStorage.hardenExistingFile(storeURL)
        PrivateStorage.hardenExistingARETGPXFiles()
        load()
    }

    @discardableResult
    func add(_ activity: RecordedActivity) -> Bool {
        do {
            // Re-read on retry: a protected/unreadable index must never be replaced
            // with the empty list shown by a failed launch-time load.
            var updated: [RecordedActivity] = []
            if FileManager.default.fileExists(atPath: storeURL.path) {
                updated = try JSONDecoder().decode([RecordedActivity].self, from: Data(contentsOf: storeURL))
            }
            updated.removeAll { $0.id == activity.id }
            updated.append(activity)
            updated.sort { $0.startedAt > $1.startedAt }
            try PrivateStorage.writeProtected(JSONEncoder().encode(updated), to: storeURL)
            activities = updated
            return true
        } catch {
            return false
        }
    }

    func delete(at offsets: IndexSet) {
        let removed = offsets.compactMap { index in
            activities.indices.contains(index) ? activities[index] : nil
        }

        for index in offsets.sorted(by: >) {
            guard activities.indices.contains(index) else { continue }
            activities.remove(at: index)
        }
        persist()

        for activity in removed {
            guard let url = gpxURL(for: activity) else { continue }
            try? FileManager.default.removeItem(at: url)
        }
    }

    func deleteAll() throws {
        try PrivateStorage.deleteAllARETGPXFiles()
        if FileManager.default.fileExists(atPath: storeURL.path) {
            try FileManager.default.removeItem(at: storeURL)
        }
        activities.removeAll()
    }

    func gpxURL(for activity: RecordedActivity) -> URL? {
        guard let filename = activity.gpxFilename else { return nil }

        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let url = documents.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private func load() {
        guard
            let data = try? Data(contentsOf: storeURL),
            let decoded = try? JSONDecoder().decode([RecordedActivity].self, from: data)
        else {
            activities = []
            return
        }

        activities = decoded.sorted { $0.startedAt > $1.startedAt }
    }

    @discardableResult
    private func persist() -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(activities)
            try PrivateStorage.writeProtected(data, to: storeURL)
            return true
        } catch {
            print("ARET activity persistence error:", error.localizedDescription)
            return false
        }
    }
}
