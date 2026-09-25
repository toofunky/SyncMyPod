import Foundation

nonisolated struct AudioTags: Equatable, Sendable {
    var title: String?
    var artist: String?
    var album: String?
    var albumArtist: String?
    var genre: String?
    var year: Int?
    var track = TagNumberPair()
    var disc = TagNumberPair()
}
