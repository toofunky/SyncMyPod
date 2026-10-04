import Foundation

/// The files and playlists this app put on a player, so a sync only ever deletes its own copies.
nonisolated struct PlayerSyncManifest: Codable, Equatable, Sendable {
    /// Keyed by the library file's path.
    var entries: [String: PlayerManifestEntry] = [:]
    /// Playlist files this app wrote, relative to the volume.
    var playlistPaths: Set<String> = []
    /// Covers and lyric files this app copied, keyed by their path relative to the volume.
    var sidecars: [String: SidecarFile] = [:]
    /// The size covers were scaled to fit, keyed like `sidecars`; absent for covers copied as they are.
    var coverPixelLimits: [String: Int] = [:]
}

nonisolated extension PlayerSyncManifest {
    /// Manifests saved by older versions lack the newer records.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entries = try container.decodeIfPresent([String: PlayerManifestEntry].self, forKey: .entries) ?? [:]
        playlistPaths = try container.decodeIfPresent(Set<String>.self, forKey: .playlistPaths) ?? []
        sidecars = try container.decodeIfPresent([String: SidecarFile].self, forKey: .sidecars) ?? [:]
        coverPixelLimits = try container.decodeIfPresent([String: Int].self, forKey: .coverPixelLimits) ?? [:]
    }
}
