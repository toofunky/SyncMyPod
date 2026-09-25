import Foundation

/// Real databases copied from a device into `SyncMyPodTests/Fixtures/` (git-ignored).
nonisolated enum RealDeviceFixture {
    static let data: Data? = load("iTunesDB")
    static let artworkDB: Data? = load("ArtworkDB")
    /// A Play Counts file and the iTunesDB it was recorded against.
    static let playCounts: Data? = load("PlayCounts")
    static let playCountsDatabase: Data? = load("iTunesDB.playcounts")

    private static func load(_ name: String) -> Data? {
        let url = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Fixtures/\(name)", directoryHint: .notDirectory)
        return try? Data(contentsOf: url)
    }
}
