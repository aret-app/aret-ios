import Foundation

enum PrivateStorage {
    static func prepareDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )

        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )

        var directoryURL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directoryURL.setResourceValues(values)
    }

    static func writeProtected(
        _ data: Data,
        to url: URL
    ) throws {
        try data.write(
            to: url,
            options: [
                .atomic,
                .completeFileProtection
            ]
        )

        try hardenExistingFile(url)
    }

    static func hardenExistingFile(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )

        var fileURL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try fileURL.setResourceValues(values)
    }

    static func hardenExistingARETGPXFiles() {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        guard
            let files = try? FileManager.default.contentsOfDirectory(
                at: documents,
                includingPropertiesForKeys: nil
            )
        else {
            return
        }

        for url in files where
            url.lastPathComponent.hasPrefix("ARET_") &&
            url.pathExtension.lowercased() == "gpx" {
            try? hardenExistingFile(url)
        }
    }

    static func deleteAllARETGPXFiles() {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        guard
            let files = try? FileManager.default.contentsOfDirectory(
                at: documents,
                includingPropertiesForKeys: nil
            )
        else {
            return
        }

        for url in files where
            url.lastPathComponent.hasPrefix("ARET_") &&
            url.pathExtension.lowercased() == "gpx" {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
