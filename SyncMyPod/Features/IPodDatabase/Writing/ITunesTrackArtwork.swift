import Foundation

/// Links an `mhit` to its ArtworkDB image.
nonisolated struct ITunesTrackArtwork: Equatable, Sendable {
    let imageID: UInt32
    /// Size of the original embedded cover, which iTunes records alongside the link.
    let sourceByteCount: Int
}
