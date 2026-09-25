import Foundation

/// Reads and safely replaces the iTunesDB on a mounted iPod.
nonisolated struct ITunesDBStore {
    let volumeURL: URL

    var databaseURL: URL { ITunesDBLoader.databaseURL(onVolume: volumeURL) }
    var backupURL: URL { databaseURL.deletingLastPathComponent().appending(path: "iTunesDB.syncmypod-backup") }

    func loadRecords() throws -> ITunesDBRecord {
        guard FileManager.default.fileExists(atPath: databaseURL.path(percentEncoded: false)) else {
            throw ITunesDBError.databaseNotFound(path: databaseURL.path(percentEncoded: false))
        }
        return try ITunesDBRecordParser(data: Data(contentsOf: databaseURL)).parse()
    }

    /// Validates `data`, backs up the current database, writes atomically, then verifies the result.
    func save(_ data: Data) throws {
        _ = try ITunesDBRecordParser(data: data).parse()
        _ = try ITunesDBParser(data: data).parse()
        try replaceBackup()
        try data.write(to: databaseURL, options: .atomic)
        try flushToDisk(databaseURL)
        guard (try? Data(contentsOf: databaseURL)) == data else {
            try restoreBackup()
            throw IPodSyncError.verificationFailed
        }
    }

    private func replaceBackup() throws {
        let manager = FileManager.default
        if manager.fileExists(atPath: backupURL.path(percentEncoded: false)) {
            try manager.removeItem(at: backupURL)
        }
        try manager.copyItem(at: databaseURL, to: backupURL)
        try flushToDisk(backupURL)
    }

    private func restoreBackup() throws {
        try Data(contentsOf: backupURL).write(to: databaseURL, options: .atomic)
        try flushToDisk(databaseURL)
    }

    private func flushToDisk(_ url: URL) throws {
        let handle = try FileHandle(forUpdating: url)
        defer { try? handle.close() }
        try handle.synchronize()
    }
}
