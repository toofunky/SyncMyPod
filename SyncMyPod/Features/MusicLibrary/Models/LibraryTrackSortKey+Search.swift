import Foundation

nonisolated extension LibraryTrackSortKey {
    func matches(_ query: TrackSearchQuery) -> Bool {
        query.matches(title, artist, albumArtist, album, composer)
    }
}
