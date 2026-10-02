import Foundation
import Testing
@testable import SyncMyPod

struct AlbumTrackOrderTests {
    private func track(_ title: String, disc: Int, number: Int) -> LibraryTrack {
        let track = LibraryTrack(filePath: "/Music/\(title).m4a")
        track.title = title
        track.discNumber = disc
        track.trackNumber = number
        return track
    }

    @Test func sortsByDiscThenTrackThenTitle() {
        let tracks = [track("d2t1", disc: 2, number: 1), track("d1t2", disc: 1, number: 2),
                      track("d1t1b", disc: 1, number: 1), track("d1t1a", disc: 1, number: 1),
                      track("d0", disc: 0, number: 5)]
        let titles = LibraryTrack.albumOrdered(tracks).map(\.title)
        #expect(titles == ["d0", "d1t1a", "d1t1b", "d1t2", "d2t1"])
    }
}
