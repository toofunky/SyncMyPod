import Foundation

/// `mhod` record types that carry a standard string payload.
nonisolated enum ITunesStringField: UInt32, Hashable, Sendable {
    case title = 1
    case location = 2
    case album = 3
    case artist = 4
    case genre = 5
    case fileType = 6
    case comment = 8
    case composer = 12
    case grouping = 13
    case albumArtist = 22
    case sortArtist = 23
    case sortTitle = 27
    case sortAlbum = 28
    case sortAlbumArtist = 29
    case sortComposer = 30
}
