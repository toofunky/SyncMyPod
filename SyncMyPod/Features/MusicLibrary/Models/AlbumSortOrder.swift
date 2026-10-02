import Foundation

nonisolated enum AlbumSortOrder: String, CaseIterable, Identifiable, Sendable {
    case albumArtist
    case album
    case year
    case genre

    var id: Self { self }

    var title: String {
        switch self {
        case .albumArtist: "Album Artist"
        case .album: "Album"
        case .year: "Year"
        case .genre: "Genre"
        }
    }

    func sorted(_ albums: [LibraryAlbum]) -> [LibraryAlbum] {
        let comparators = comparators
        return albums.sorted { lhs, rhs in
            for compare in comparators {
                let result = compare(lhs, rhs)
                if result != .orderedSame { return result == .orderedAscending }
            }
            return false
        }
    }

    private var comparators: [(LibraryAlbum, LibraryAlbum) -> ComparisonResult] {
        switch self {
        case .albumArtist: [Self.byArtist, Self.byYear, Self.byTitle]
        case .album: [Self.byTitle, Self.byArtist]
        case .year: [Self.byYear, Self.byArtist, Self.byTitle]
        case .genre: [Self.byGenre, Self.byArtist, Self.byYear, Self.byTitle]
        }
    }

    private static func byArtist(_ lhs: LibraryAlbum, _ rhs: LibraryAlbum) -> ComparisonResult {
        lhs.artistSortName.localizedStandardCompare(rhs.artistSortName)
    }

    private static func byTitle(_ lhs: LibraryAlbum, _ rhs: LibraryAlbum) -> ComparisonResult {
        lhs.titleSortName.localizedStandardCompare(rhs.titleSortName)
    }

    private static func byGenre(_ lhs: LibraryAlbum, _ rhs: LibraryAlbum) -> ComparisonResult {
        lhs.genreSortName.localizedStandardCompare(rhs.genreSortName)
    }

    /// Albums without a year sort after dated ones.
    private static func byYear(_ lhs: LibraryAlbum, _ rhs: LibraryAlbum) -> ComparisonResult {
        let left = lhs.year > 0 ? lhs.year : .max
        let right = rhs.year > 0 ? rhs.year : .max
        if left == right { return .orderedSame }
        return left < right ? .orderedAscending : .orderedDescending
    }
}
