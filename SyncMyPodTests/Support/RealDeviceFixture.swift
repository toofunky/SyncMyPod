import Foundation

/// Real databases copied from a device into `SyncMyPodTests/Fixtures/` (git-ignored).
nonisolated enum RealDeviceFixture {
    static let data: Data? = load("iTunesDB")
    static let artworkDB: Data? = load("ArtworkDB")

    private static func load(_ name: String) -> Data? {
        let url = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Fixtures/\(name)", directoryHint: .notDirectory)
        return try? Data(contentsOf: url)
    }
}
