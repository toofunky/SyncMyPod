import Foundation

/// An M3U playlist to write on the player.
nonisolated struct PlayerPlaylistFile: Equatable, Sendable {
    /// Relative to the volume.
    let path: String
    let contents: String
    var format = PlayerPlaylistFormat.m3u8

    var data: Data { format.encoded(contents) }
}
