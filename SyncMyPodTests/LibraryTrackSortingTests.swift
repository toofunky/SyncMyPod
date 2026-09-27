import Foundation
import Testing
@testable import SyncMyPod

struct LibraryTrackSortingTests {
    private func track(_ title: String, artist: String = "A", album: String = "X", albumArtist: String = "",
                       composer: String? = nil, disc: Int = 1, number: Int = 0) -> LibraryTrack {
        let track = LibraryTrack(filePath: "/Music/\(artist)/\(album)/\(title).m4a")
        track.title = title
        track.artist = artist
        track.album = album
        track.albumArtist = albumArtist
        track.composerTag = composer
        track.discNumber = disc
        track.trackNumber = number
        return track
    }

    private func titles(_ tracks: [LibraryTrack], by primary: KeyPathComparator<LibraryTrack>) -> [String] {
        LibraryTrack.sorted(tracks, keys: LibraryTrack.sortKeys(for: tracks), by: primary).map(\.title)
    }

    @Test func artistSubSortsByAlbumDiscAndTrack() {
        let tracks = [
            track("d2t1", album: "Y", disc: 2, number: 1),
            track("b", artist: "B"),
            track("d1t2", album: "Y", disc: 1, number: 2),
            track("x1", album: "X", number: 1),
            track("d1t1", album: "Y", disc: 1, number: 1),
        ]
        #expect(titles(tracks, by: KeyPathComparator(\.artist)) == ["x1", "d1t1", "d1t2", "d2t1", "b"])
    }

    @Test func composerSortsMissingComposersFirst() {
        let tracks = [track("b", composer: "Bach"), track("none"), track("a", composer: "Arvo Pärt")]
        #expect(titles(tracks, by: KeyPathComparator(\.composer)) == ["none", "a", "b"])
    }

    @Test func searchMatchesComposer() {
        let keys = LibraryTrack.sortKeys(for: [track("Spiegel", composer: "Arvo Pärt"), track("Other")])
        #expect(keys.filter { $0.matches(TrackSearchQuery("arvo part")) }.map(\.title) == ["Spiegel"])
    }

    @Test func albumSubSortsByAlbumArtistBeforeTrack() {
        let tracks = [
            track("q1", album: "Hits", albumArtist: "Queen", number: 1),
            track("a2", album: "Hits", albumArtist: "ABBA", number: 2),
            track("q2", album: "Hits", albumArtist: "Queen", number: 2),
            track("a1", album: "Hits", albumArtist: "ABBA", number: 1),
        ]
        #expect(titles(tracks, by: KeyPathComparator(\.album)) == ["a1", "a2", "q1", "q2"])
    }

    @Test func discSubSortsByArtistAlbumAndTrack() {
        let tracks = [
            track("b1", artist: "B", number: 1),
            track("a2", number: 2),
            track("a1", number: 1),
            track("d2", disc: 2),
        ]
        #expect(titles(tracks, by: KeyPathComparator(\.discNumber)) == ["a1", "a2", "b1", "d2"])
    }

    @Test func trackSubSortsByArtistAlbumAndDisc() {
        let tracks = [
            track("b-d1", artist: "B", number: 1),
            track("a-d2", disc: 2, number: 1),
            track("a-d1", disc: 1, number: 1),
        ]
        #expect(titles(tracks, by: KeyPathComparator(\.trackNumber)) == ["a-d1", "a-d2", "b-d1"])
    }

    @Test func descendingPrimaryKeepsTieBreakersAscending() {
        let tracks = [
            track("a2", number: 2),
            track("b1", artist: "B", number: 1),
            track("a1", number: 1),
        ]
        #expect(titles(tracks, by: KeyPathComparator(\.artist, order: .reverse)) == ["b1", "a1", "a2"])
    }

    @Test func missingNumbersFallBackToTitle() {
        let tracks = [track("Zebra"), track("Apple"), track("Mango")]
        #expect(titles(tracks, by: KeyPathComparator(\.artist)) == ["Apple", "Mango", "Zebra"])
    }

    @Test func albumArtistIgnoresLeadingArticles() {
        let tracks = [
            track("t", albumArtist: "Travis"),
            track("k", albumArtist: "The Killers"),
            track("a", albumArtist: "Arcade Fire"),
        ]
        #expect(titles(tracks, by: KeyPathComparator(\.albumArtist)) == ["a", "k", "t"])
    }

    @Test func searchStillMatchesLeadingArticle() {
        let keys = LibraryTrack.sortKeys(for: [track("Mr. Brightside", artist: "The Killers"), track("Other")])
        #expect(keys.filter { $0.matches(TrackSearchQuery("the killers")) }.map(\.title) == ["Mr. Brightside"])
    }
}
