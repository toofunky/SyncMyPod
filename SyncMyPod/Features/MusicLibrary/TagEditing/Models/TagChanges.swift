import Foundation

/// The tags to write to one file. `nil` leaves a tag as it is; an empty string or zero removes it.
nonisolated struct TagChanges: Equatable, Sendable {
    var title: String?
    var artist: String?
    var album: String?
    var albumArtist: String?
    var composer: String?
    var genre: String?
    var year: Int?
    var track: TagNumberPair?
    var disc: TagNumberPair?
    var artwork = ArtworkChange.keep

    var isEmpty: Bool { self == TagChanges() }
}
