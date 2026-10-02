import Foundation
import Testing
@testable import SyncMyPod

struct ArtistAlbumSectionTests {
    private func track(_ title: String, album: String, year: Int, disc: Int = 1, number: Int) -> LibraryTrack {
        let track = LibraryTrack(filePath: "/Music/A/\(album)/\(title).m4a")
        track.title = title
        track.artist = "A"
        track.album = album
        track.year = year
        track.discNumber = disc
        track.trackNumber = number
        return track
    }

    @Test func albumsRunEarliestToLatestWithUndatedLast() {
        let sections = ArtistAlbumSection.sections(from: [
            track("a", album: "Later", year: 2010, number: 1),
            track("b", album: "Undated", year: 0, number: 1),
            track("c", album: "Debut", year: 1995, number: 1),
        ])
        #expect(sections.map(\.album.title) == ["Debut", "Later", "Undated"])
    }

    @Test func albumOrderSortsByTitleIgnoringArticles() {
        let sections = ArtistAlbumSection.sections(from: [
            track("a", album: "The Zoo", year: 1990, number: 1),
            track("b", album: "Apples", year: 2010, number: 1),
            track("c", album: "Middle", year: 2000, number: 1),
        ], sortedBy: .album)
        #expect(sections.map(\.album.title) == ["Apples", "Middle", "The Zoo"])
    }

    @Test func tracksAreInDiscAndTrackOrder() {
        let sections = ArtistAlbumSection.sections(from: [
            track("d2t1", album: "X", year: 2000, disc: 2, number: 1),
            track("d1t2", album: "X", year: 2000, disc: 1, number: 2),
            track("d1t1", album: "X", year: 2000, disc: 1, number: 1),
        ])
        #expect(sections.first?.tracks.map(\.title) == ["d1t1", "d1t2", "d2t1"])
        #expect(sections.first?.hasSeveralDiscs == true)
    }
}
