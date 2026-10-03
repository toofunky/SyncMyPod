import Foundation

/// A cover image or lyric file to copy onto the player.
nonisolated struct PlayerSidecarCopy: Equatable, Sendable {
    let source: SidecarFile
    /// Relative to the volume.
    let destination: String
}
