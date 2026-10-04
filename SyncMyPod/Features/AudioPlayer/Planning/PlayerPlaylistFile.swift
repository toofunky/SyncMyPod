import Foundation

/// An M3U8 playlist to write on the player.
nonisolated struct PlayerPlaylistFile: Equatable, Sendable {
    /// Relative to the volume.
    let path: String
    let contents: String
}
