import Foundation

nonisolated extension LibraryAlbum {
    func matches(_ query: TrackSearchQuery) -> Bool {
        query.matches(title, artist)
    }
}
