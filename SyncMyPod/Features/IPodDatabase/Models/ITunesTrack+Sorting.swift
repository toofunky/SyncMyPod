import Foundation

/// The strings the iPod sorts by: the synced sort names, or the plain value without a leading article.
nonisolated extension ITunesTrack {
    var sortingTitle: String { strings[.sortTitle] ?? title.sortName }
    var sortingArtist: String { strings[.sortArtist] ?? artist.sortName }
    var sortingAlbumArtist: String { strings[.sortAlbumArtist] ?? albumArtist.sortName }
    var sortingAlbum: String { strings[.sortAlbum] ?? album.sortName }
    var sortingComposer: String { strings[.sortComposer] ?? composer.sortName }
}
