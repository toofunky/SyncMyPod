import Foundation

nonisolated extension ITunesTrack {
    func matches(_ query: TrackSearchQuery) -> Bool {
        query.matches(title, artist, albumArtist, album, composer)
    }
}
