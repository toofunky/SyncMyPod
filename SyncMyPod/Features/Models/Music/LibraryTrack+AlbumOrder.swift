import Foundation

extension LibraryTrack {
    /// Play order within an album: disc, then track number, then title.
    static func albumOrdered(_ tracks: [LibraryTrack]) -> [LibraryTrack] {
        tracks.sorted { lhs, rhs in
            if lhs.discNumber != rhs.discNumber { return lhs.discNumber < rhs.discNumber }
            if lhs.trackNumber != rhs.trackNumber { return lhs.trackNumber < rhs.trackNumber }
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }
}
