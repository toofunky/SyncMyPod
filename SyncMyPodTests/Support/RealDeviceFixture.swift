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
    /// The empty ArtworkDB macOS wrote to that nano, which lists its four cover formats.
    static let nanoArtworkDB: Data? = load("ArtworkDB.nano")
    /// The same nano's SysInfoExtended (read over USB) and the `iTunes Library.itlp` folder iTunes wrote with it.
    static let nanoSysInfoExtended: String? = load("SysInfoExtended.nano.xml").map { String(decoding: $0, as: UTF8.self) }
    static let nanoLibraryFolder: URL? = {
        let url = fixturesURL.appending(path: "iTunes Library.itlp", directoryHint: .isDirectory)
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) ? url : nil
    }()

    private static let fixturesURL = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "Fixtures", directoryHint: .isDirectory)

    private static func load(_ name: String) -> Data? {
        try? Data(contentsOf: fixturesURL.appending(path: name, directoryHint: .notDirectory))
    }
}
