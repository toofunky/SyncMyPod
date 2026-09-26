import Foundation

/// A sortable library column; compares `LibraryTrackSortKey`s directly because `KeyPathComparator` is ~5× slower.
nonisolated enum LibraryTrackSortField: Sendable {
    case title, artist, albumArtist, album, genre, trackNumber, discNumber, duration, bitrate, codecName

    init(keyPath: PartialKeyPath<LibraryTrack>) {
        switch keyPath {
        case \LibraryTrack.title: self = .title
        case \LibraryTrack.artist: self = .artist
        case \LibraryTrack.album: self = .album
        case \LibraryTrack.genre: self = .genre
        case \LibraryTrack.trackNumber: self = .trackNumber
        case \LibraryTrack.discNumber: self = .discNumber
        case \LibraryTrack.duration: self = .duration
        case \LibraryTrack.bitrate: self = .bitrate
        case \LibraryTrack.codecName: self = .codecName
        default: self = .albumArtist
        }
    }

    /// Ascending tie-breakers that keep albums in play order after sorting by this field.
    var tieBreakers: [LibraryTrackSortField] {
        let fields: [LibraryTrackSortField] = switch self {
        case .album: [.albumArtist, .discNumber, .trackNumber, .title]
        case .discNumber: [.artist, .album, .trackNumber, .title]
        case .trackNumber: [.artist, .album, .discNumber, .title]
        default: [.album, .discNumber, .trackNumber, .title]
        }
        return fields.filter { $0 != self }
    }

    func compare(_ lhs: LibraryTrackSortKey, _ rhs: LibraryTrackSortKey) -> ComparisonResult {
        switch self {
        case .title: lhs.title.localizedStandardCompare(rhs.title)
        case .artist: lhs.artist.localizedStandardCompare(rhs.artist)
        case .albumArtist: lhs.albumArtist.localizedStandardCompare(rhs.albumArtist)
        case .album: lhs.album.localizedStandardCompare(rhs.album)
        case .genre: lhs.genre.localizedStandardCompare(rhs.genre)
        case .trackNumber: Self.compare(lhs.trackNumber, rhs.trackNumber)
        case .discNumber: Self.compare(lhs.discNumber, rhs.discNumber)
        case .duration: Self.compare(lhs.duration, rhs.duration)
        case .bitrate: Self.compare(lhs.bitrate, rhs.bitrate)
        case .codecName: lhs.codecName.localizedStandardCompare(rhs.codecName)
        }
    }

    private static func compare<Value: Comparable>(_ lhs: Value, _ rhs: Value) -> ComparisonResult {
        lhs < rhs ? .orderedAscending : lhs > rhs ? .orderedDescending : .orderedSame
    }
}
