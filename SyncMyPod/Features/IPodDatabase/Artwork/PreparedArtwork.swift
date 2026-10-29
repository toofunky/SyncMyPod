import Foundation

/// A cover whose pixels are already stored, waiting to be linked to its track.
nonisolated struct PreparedArtwork: Equatable, Sendable {
    let trackArtwork: ITunesTrackArtwork
    let thumbnails: [ArtworkThumbnail]
}
