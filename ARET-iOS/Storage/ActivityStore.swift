import Foundation
import Combine

@MainActor
final class ActivityStore: ObservableObject {
    @Published private(set) var activities: [RecordedActivity] = []

    private let storeURL: URL

    init() {
        let directory = FileManager.default.urls(
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

    func add(_ activity: RecordedActivity) {
        activities.removeAll { $0.id == activity.id }
        activities.insert(activity, at: 0)
        activities.sort { $0.startedAt > $1.startedAt }
        persist()
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

    func deleteAll() {
        activities.removeAll()
        try? FileManager.default.removeItem(at: storeURL)
        PrivateStorage.deleteAllARETGPXFiles()
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

    private func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(activities)
            try PrivateStorage.writeProtected(data, to: storeURL)
        } catch {
            print("ARET activity persistence error:", error.localizedDescription)
        }
    }
}
