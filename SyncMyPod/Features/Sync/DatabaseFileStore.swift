import Foundation

/// Reads and safely replaces a record-tree database (iTunesDB or ArtworkDB) on a mounted iPod.
nonisolated struct DatabaseFileStore: Sendable {
    let fileURL: URL
    let layout: RecordTreeLayout
    /// Extra checks a new database must pass before it replaces the current one.
    let validate: @Sendable (Data) throws -> Void

    static func iTunesDB(onVolume volumeURL: URL) -> DatabaseFileStore {
        DatabaseFileStore(fileURL: ITunesDBLoader.databaseURL(onVolume: volumeURL), layout: .iTunesDB) {
            _ = try ITunesDBParser(data: $0).parse()
        }
    }

    static func artworkDB(onVolume volumeURL: URL) -> DatabaseFileStore {
        let url = volumeURL.appending(path: "iPod_Control/Artwork/ArtworkDB", directoryHint: .notDirectory)
        return DatabaseFileStore(fileURL: url, layout: .artworkDB) { _ in }
    }

    var backupURL: URL {
        fileURL.deletingLastPathComponent().appending(path: "\(fileURL.lastPathComponent).syncmypod-backup")
    }

    var exists: Bool { FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) }

    func loadRecords() throws -> ITunesDBRecord {
        guard exists else { throw ITunesDBError.databaseNotFound(path: fileURL.path(percentEncoded: false)) }
        return try ITunesDBRecordParser(data: Data(contentsOf: fileURL), layout: layout).parse()
    }

    /// Validates `data`, backs up the current file, writes atomically, then verifies the result.
    func save(_ data: Data) throws {
        _ = try ITunesDBRecordParser(data: data, layout: layout).parse()
        try validate(data)
        if exists {
            try replaceBackup()
        } else {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
        }
        try write(data)
        guard (try? Data(contentsOf: fileURL)) == data else {
            try restore(FileManager.default.fileExists(atPath: backupURL.path(percentEncoded: false))
                        ? Data(contentsOf: backupURL) : nil)
            throw IPodSyncError.verificationFailed
        }
    }

    /// Puts back `original`, or removes the file if there wasn't one.
    func restore(_ original: Data?) throws {
        guard let original else {
            if exists { try FileManager.default.removeItem(at: fileURL) }
            return
        }
        try write(original)
    }

    private func replaceBackup() throws {
        let manager = FileManager.default
        if manager.fileExists(atPath: backupURL.path(percentEncoded: false)) {
            try manager.removeItem(at: backupURL)
        }
        try manager.copyItem(at: fileURL, to: backupURL)
        try flushToDisk(backupURL)
    }

    private func write(_ data: Data) throws {
        try data.write(to: fileURL, options: .atomic)
        try flushToDisk(fileURL)
    }

    private func flushToDisk(_ url: URL) throws {
        let handle = try FileHandle(forUpdating: url)
        defer { try? handle.close() }
        try handle.synchronize()
    }
}
