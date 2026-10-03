import Foundation
import Testing
@testable import SyncMyPod

struct PlaybackQueueTests {
    private let tracks = (1...5).map { LibraryTrack(filePath: "/Music/\($0).m4a") }

    @Test func startsAtTheChosenSongAndPlaysOn() {
        var queue = PlaybackQueue(tracks: tracks, startingAt: 2, shuffled: false)
        #expect(queue.current?.filePath == "/Music/3.m4a")
        let moves = [queue.advance(wrapping: false), queue.advance(wrapping: false)]
        #expect(moves == [true, true])
        #expect(queue.current?.filePath == "/Music/5.m4a")
        let movedPastEnd = queue.advance(wrapping: false)
        #expect(!movedPastEnd)
    }

    @Test func repeatingWrapsBothWays() {
        var queue = PlaybackQueue(tracks: tracks, startingAt: 4, shuffled: false)
        let advanced = queue.advance(wrapping: true)
        #expect(advanced && queue.current?.filePath == "/Music/1.m4a")
        let retreated = queue.retreat(wrapping: true)
        #expect(retreated && queue.current?.filePath == "/Music/5.m4a")
    }

    @Test func shufflingKeepsTheCurrentSongAndEverySong() {
        var queue = PlaybackQueue(tracks: tracks, startingAt: 3, shuffled: true)
        #expect(queue.current?.filePath == "/Music/4.m4a")
        #expect(queue.order.sorted() == Array(tracks.indices))
        queue.setShuffled(false)
        #expect(queue.current?.filePath == "/Music/4.m4a")
        #expect(queue.order == Array(tracks.indices))
    }

    @Test func emptyQueueHasNothingToPlay() {
        var queue = PlaybackQueue()
        #expect(queue.current == nil)
        let moves = [queue.advance(wrapping: true), queue.retreat(wrapping: true)]
        #expect(moves == [false, false])
    }
}
