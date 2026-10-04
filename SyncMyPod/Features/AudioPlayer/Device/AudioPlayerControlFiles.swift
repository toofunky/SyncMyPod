import Foundation

/// The hidden folder at the root of a player's volume holding its config and sync manifest.
nonisolated struct AudioPlayerControlFiles: Sendable {
    static let folderName = ".syncmypod"

    let volumeURL: URL

    var folderURL: URL { volumeURL.appending(path: Self.folderName, directoryHint: .isDirectory) }
    var configURL: URL { folderURL.appending(path: "Player.plist") }
    var manifestURL: URL { folderURL.appending(path: "Manifest.plist") }

    func config() -> AudioPlayerConfig? {
        load(AudioPlayerConfig.self, from: configURL)
    }

    func save(_ config: AudioPlayerConfig) throws {
        try save(config, to: configURL)
    }

    /// An empty manifest when there's none or it can't be read.
    func manifest() -> PlayerSyncManifest {
        load(PlayerSyncManifest.self, from: manifestURL) ?? PlayerSyncManifest()
    }

    func save(_ manifest: PlayerSyncManifest) throws {
        try save(manifest, to: manifestURL)
    }

    /// Forgets the player; its music and playlists stay.
    func removeConfig() throws {
        try FileManager.default.removeItem(at: folderURL)
    }

    private func load<Value: Decodable>(_ type: Value.Type, from url: URL) -> Value? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? PropertyListDecoder().decode(type, from: data)
    }

    /// Binary so modification dates round-trip exactly.
    private func save(_ value: some Encodable, to url: URL) throws {
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        try encoder.encode(value).write(to: url, options: .atomic)
    }
}
