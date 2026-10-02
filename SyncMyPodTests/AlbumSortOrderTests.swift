import Foundation
import Testing
@testable import SyncMyPod

struct AlbumSortOrderTests {
    private static func album(_ title: String, artist: String, year: Int = 0, genre: String = "Rock") -> LibraryAlbum {
        LibraryAlbum(id: "\(artist)/\(title)", title: title, artist: artist, titleSortName: title.sortName,
                     artistSortName: artist.sortName, genre: genre,
                     genreSortName: genre.sortName, year: year, trackCount: 1, artworkPath: nil,
                     artworkFingerprint: nil)
    }

    private let albums = [
        Self.album("Hot Fuss", artist: "The Killers", year: 2004),
        Self.album("Sam's Town", artist: "The Killers", year: 2006),
        Self.album("Abbey Road", artist: "Beatles", year: 1969, genre: "Pop"),
        Self.album("Untitled", artist: "Zeta", genre: "Electronic"),
        Self.album("The Wall", artist: "Pink Floyd", year: 1979),
    ]

    @Test func albumArtistIgnoresArticlesThenSortsByYear() {
        let titles = AlbumSortOrder.albumArtist.sorted(albums).map(\.title)
        #expect(titles == ["Abbey Road", "Hot Fuss", "Sam's Town", "The Wall", "Untitled"])
    }

    @Test func albumSortsByTitleIgnoringArticles() {
        let titles = AlbumSortOrder.album.sorted(albums).map(\.title)
        #expect(titles == ["Abbey Road", "Hot Fuss", "Sam's Town", "Untitled", "The Wall"])
    }

    @Test func genreSortsByGenreThenAlbumArtist() {
        let titles = AlbumSortOrder.genre.sorted(albums).map(\.title)
        #expect(titles == ["Untitled", "Abbey Road", "Hot Fuss", "Sam's Town", "The Wall"])
    }

    @Test func yearPutsUndatedAlbumsLast() {
        let titles = AlbumSortOrder.year.sorted(albums).map(\.title)
        #expect(titles == ["Abbey Road", "The Wall", "Hot Fuss", "Sam's Town", "Untitled"])
    }
}
