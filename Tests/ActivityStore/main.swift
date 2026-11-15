import Foundation

struct RecordedActivity: Codable {
    let id: UUID
    let startedAt: Date
    let gpxFilename: String?
}
enum PrivateStorage {
    nonisolated(unsafe) static var failWrites = false
    static func prepareDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    static func hardenExistingFile(_ url: URL) throws {}
    static func hardenExistingARETGPXFiles() {}
    static func deleteAllARETGPXFiles() throws {
        if failWrites { throw CocoaError(.fileWriteNoPermission) }
    }
    static func writeProtected(_ data: Data, to url: URL) throws {
        if failWrites { throw CocoaError(.fileWriteOutOfSpace) }
        try data.write(to: url, options: .atomic)
    }
}
func check(_ condition: Bool, _ message: String) { precondition(condition, message) }
let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
defer { try? FileManager.default.removeItem(at: directory) }
let store = ActivityStore(storageDirectory: directory)
let first = RecordedActivity(id: UUID(), startedAt: Date(timeIntervalSince1970: 100), gpxFilename: nil)
let second = RecordedActivity(id: UUID(), startedAt: Date(timeIntervalSince1970: 200), gpxFilename: nil)
check(store.add(first), "initial save")
let url = directory.appendingPathComponent("activities.json")
let initialBytes = try Data(contentsOf: url)
PrivateStorage.failWrites = true
check(!store.add(second), "disk full reports failure")
check(store.activities.map(\.id) == [first.id], "failed save never publishes phantom activity")
check(try Data(contentsOf: url) == initialBytes, "failed save retains history")
PrivateStorage.failWrites = false
check(store.add(second), "retry")
check(store.add(second), "repeated recovery")
check(store.activities.map(\.id) == [second.id, first.id], "stable ID prevents duplicate")
check(ActivityStore(storageDirectory: directory).activities.count == 2, "history survives restart")
let corrupt = Data("corrupt index".utf8)
try corrupt.write(to: url)
let coldStore = ActivityStore(storageDirectory: directory)
check(!coldStore.add(first), "unreadable index must not be replaced")
check(try Data(contentsOf: url) == corrupt, "corrupt history preserved")
try initialBytes.write(to: url)
check(coldStore.add(second), "retry rereads restored index")
check(coldStore.activities.count == 2, "retry preserves prior history")
PrivateStorage.failWrites = true
do {
    try coldStore.deleteAll()
    fatalError("erase failure must propagate")
} catch { }
check(coldStore.activities.count == 2, "failed deletion retains UI history")
check(FileManager.default.fileExists(atPath: url.path), "failed deletion retains index")
PrivateStorage.failWrites = false
try coldStore.deleteAll()
check(coldStore.activities.isEmpty, "successful deletion clears history")
check(!FileManager.default.fileExists(atPath: url.path), "successful deletion removes index")
print("PASS: ActivityStore failure rollback, disk preservation, retry, duplicate recovery, restart, corrupt-index protection, deletion failure/success")
