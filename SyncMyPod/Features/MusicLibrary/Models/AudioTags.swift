import Foundation

nonisolated struct AudioTags: Equatable, Sendable {
    var title: String?
    var artist: String?
    var album: String?
    var albumArtist: String?
    var composer: String?
    var genre: String?
    var year: Int?
    var track = TagNumberPair()
    var disc = TagNumberPair()
    var sortTitle: String?
    var sortArtist: String?
    var sortAlbumArtist: String?
    var sortAlbum: String?
    var sortComposer: String?
    var hasLyrics = false
}
