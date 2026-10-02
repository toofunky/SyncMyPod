import Foundation

extension LibraryAlbum {
    static func albums(from tracks: [LibraryTrack]) -> [LibraryAlbum] {
        Dictionary(grouping: tracks, by: \.syncAlbumKey).map { LibraryAlbum(key: $0.key, tracks: $0.value) }
    }

    /// `tracks` must be non-empty; the genre comes from the first song in play order,
    /// and the cover from the first song that has one.
    init(key: String, tracks: [LibraryTrack]) {
        let ordered = LibraryTrack.albumOrdered(tracks)
        let first = ordered[0]
        let artworkTrack = ordered.first { $0.artworkFingerprint != nil }
        self.init(id: key, title: first.syncAlbum, artist: first.syncArtist,
                  titleSortName: first.syncAlbum.sortName(tagged: first.sortAlbumTag),
                  artistSortName: first.syncArtistSortName, genre: first.syncGenre,
                  genreSortName: first.syncGenre.sortName, year: tracks.map(\.year).max() ?? 0,
                  trackCount: tracks.count, artworkPath: artworkTrack?.filePath,
                  artworkFingerprint: artworkTrack?.artworkFingerprint)
    }
}
