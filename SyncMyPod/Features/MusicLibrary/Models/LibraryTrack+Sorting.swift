import Foundation

extension LibraryTrack {
    /// Sorts by the clicked column, then by ascending tie-breakers that keep albums in play order.
    /// `keys` must come from `sortKeys(for: tracks)`; building them is the slow part, so callers can cache them.
    static func sorted(_ tracks: [LibraryTrack], keys: [LibraryTrackSortKey],
                       by primary: KeyPathComparator<LibraryTrack>) -> [LibraryTrack] {
        let field = LibraryTrackSortField(keyPath: primary.keyPath)
        let tieBreakers = field.tieBreakers
        let reversed = primary.order == .reverse
        return keys.sorted { lhs, rhs in
            let result = field.compare(lhs, rhs)
            if result != .orderedSame {
                return reversed ? result == .orderedDescending : result == .orderedAscending
            }
            for tieBreaker in tieBreakers {
                let result = tieBreaker.compare(lhs, rhs)
                if result != .orderedSame { return result == .orderedAscending }
            }
            return false
        }
        .map { tracks[$0.index] }
    }

    static func sortKeys(for tracks: [LibraryTrack]) -> [LibraryTrackSortKey] {
        tracks.enumerated().map { LibraryTrackSortKey(index: $0.offset, track: $0.element) }
    }
}
