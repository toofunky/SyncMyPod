import Foundation

/// One stored thumbnail: where its pixels live in the format's `.ithmb` file.
nonisolated struct ArtworkThumbnail: Hashable, Sendable {
    let format: ArtworkFormat
    let offset: UInt32
    let horizontalPadding: Int
    let verticalPadding: Int
}
