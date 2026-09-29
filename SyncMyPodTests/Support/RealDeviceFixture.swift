import Foundation

/// Real databases copied from a device into `SyncMyPodTests/Fixtures/` (git-ignored).
nonisolated enum RealDeviceFixture {
    static let data: Data? = load("iTunesDB")
    static let artworkDB: Data? = load("ArtworkDB")
    /// A Play Counts file and the iTunesDB it was recorded against.
    static let playCounts: Data? = load("PlayCounts")
    static let playCountsDatabase: Data? = load("iTunesDB.playcounts")
    /// A nano's iTunesCDB, and its FireWire GUID as hex text, for checking hashAB against iTunes' signature.
    static let compressedDatabase: Data? = load("iTunesCDB")
    static let compressedDatabaseFireWireID: String? = load("iTunesCDB.firewireid")
        .flatMap { String(data: $0, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) }

    private static func load(_ name: String) -> Data? {
        let url = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Fixtures/\(name)", directoryHint: .notDirectory)
        return try? Data(contentsOf: url)
    }
}
