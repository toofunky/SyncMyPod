import Foundation

/// The files and playlists this app put on a player, so a sync only ever deletes its own copies.
nonisolated struct PlayerSyncManifest: Codable, Equatable, Sendable {
    /// Keyed by the library file's path.
    var entries: [String: PlayerManifestEntry] = [:]
    /// Playlist files this app wrote, relative to the volume.
    var playlistPaths: Set<String> = []
    /// Covers and lyric files this app copied, keyed by their path relative to the volume.
    var sidecars: [String: SidecarFile] = [:]
}

nonisolated extension PlayerSyncManifest {
    /// Manifests saved before covers and lyrics were copied have no `sidecars`.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entries = try container.decodeIfPresent([String: PlayerManifestEntry].self, forKey: .entries) ?? [:]
        playlistPaths = try container.decodeIfPresent(Set<String>.self, forKey: .playlistPaths) ?? []
        sidecars = try container.decodeIfPresent([String: SidecarFile].self, forKey: .sidecars) ?? [:]
    }
}
