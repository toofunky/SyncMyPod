import Foundation

/// A cover image or lyric file to copy onto the player.
nonisolated struct PlayerSidecarCopy: Equatable, Sendable {
    let source: SidecarFile
    /// Relative to the volume.
    let destination: String
    /// For a cover, the size it's scaled down to fit; `nil` copies it as it is.
    var pixelLimit: Int?
}
