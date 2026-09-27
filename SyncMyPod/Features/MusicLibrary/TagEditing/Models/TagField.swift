import Foundation

enum TagField: CaseIterable, Hashable, Sendable {
    case title
    case artist
    case albumArtist
    case album
    case composer
    case genre
    case year
    case trackNumber
    case trackCount
    case discNumber
    case discCount
    case sortTitle
    case sortArtist
    case sortAlbumArtist
    case sortAlbum
    case sortComposer

    var label: String {
        switch self {
        case .title: "Title"
        case .artist: "Artist"
        case .albumArtist: "Album Artist"
        case .album: "Album"
        case .composer: "Composer"
        case .genre: "Genre"
        case .year: "Year"
        case .trackNumber, .discNumber: "Number"
        case .trackCount, .discCount: "Count"
        case .sortTitle: "Sort Title"
        case .sortArtist: "Sort Artist"
        case .sortAlbumArtist: "Sort Album Artist"
        case .sortAlbum: "Sort Album"
        case .sortComposer: "Sort Composer"
        }
    }

    /// The track's value as the editor shows it; unset numbers are blank.
    func value(of track: LibraryTrack) -> String {
        switch self {
        case .title: track.title
        case .artist: track.artist
        case .albumArtist: track.albumArtist
        case .album: track.album
        case .composer: track.composer
        case .genre: track.genre
        case .year: Self.text(track.year)
        case .trackNumber: Self.text(track.trackNumber)
        case .trackCount: Self.text(track.trackCount)
        case .discNumber: Self.text(track.discNumber)
        case .discCount: Self.text(track.discCount)
        case .sortTitle: track.sortTitleTag ?? ""
        case .sortArtist: track.sortArtistTag ?? ""
        case .sortAlbumArtist: track.sortAlbumArtistTag ?? ""
        case .sortAlbum: track.sortAlbumTag ?? ""
        case .sortComposer: track.sortComposerTag ?? ""
        }
    }

    /// The field a sort field orders, whose name without a leading article is used when the sort tag is empty.
    var sortedField: TagField? {
        switch self {
        case .sortTitle: .title
        case .sortArtist: .artist
        case .sortAlbumArtist: .albumArtist
        case .sortAlbum: .album
        case .sortComposer: .composer
        default: nil
        }
    }

    /// Reads the leading digits, so `"2004-05-01"` is 2004; anything else is 0.
    static func number(from text: String) -> Int {
        Int(text.trimmingCharacters(in: .whitespaces).prefix { $0.isASCII && $0.isNumber }) ?? 0
    }

    private static func text(_ number: Int) -> String {
        number > 0 ? String(number) : ""
    }
}
