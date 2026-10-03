import Foundation

/// The files and playlists this app put on a player, so a sync only ever deletes its own copies.
nonisolated struct PlayerSyncManifest: Codable, Equatable, Sendable {
    /// Keyed by the library file's path.
    var entries: [String: PlayerManifestEntry] = [:]
    /// Playlist files this app wrote, relative to the volume.
    var playlistPaths: Set<String> = []
}
