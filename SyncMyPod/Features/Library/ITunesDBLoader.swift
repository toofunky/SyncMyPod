import Foundation

nonisolated struct ITunesDBLoader: Sendable {
    static let live = ITunesDBLoader { volumeURL in
        try await readDatabase(onVolume: volumeURL)
    }

    let load: @Sendable (URL) async throws -> ITunesDatabase

    static func databaseURL(onVolume volumeURL: URL) -> URL {
        volumeURL.appending(path: "iPod_Control/iTunes/iTunesDB", directoryHint: .notDirectory)
    }

    static func compressedDatabaseURL(onVolume volumeURL: URL) -> URL {
        volumeURL.appending(path: "iPod_Control/iTunes/iTunesCDB", directoryHint: .notDirectory)
    }

    /// Nano 5G and later read iTunesCDB in preference to iTunesDB, which iTunes leaves empty.
    static func readableDatabaseURL(onVolume volumeURL: URL) -> URL {
        let compressed = compressedDatabaseURL(onVolume: volumeURL)
        let size = (try? compressed.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        return size > 0 ? compressed : databaseURL(onVolume: volumeURL)
    }

    @concurrent
    private static func readDatabase(onVolume volumeURL: URL) async throws -> ITunesDatabase {
        let url = readableDatabaseURL(onVolume: volumeURL)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ITunesDBError.databaseNotFound(path: url.path)
        }
        return try ITunesDBParser(data: ITunesCDB.decompress(Data(contentsOf: url))).parse()
    }
}

#if DEBUG
nonisolated extension ITunesDBLoader {
    static let preview = ITunesDBLoader { _ in .preview }

    static let missingDatabase = ITunesDBLoader { volumeURL in
        throw ITunesDBError.databaseNotFound(path: databaseURL(onVolume: volumeURL).path)
    }
}
#endif
