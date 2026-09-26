import Foundation
import Testing
@testable import SyncMyPod

struct LibraryIndexRecordBuilderTests {
    private func track(_ title: String, album: String = "", trackNumber: Int = 0) -> ITunesTrack {
        ITunesTrack(id: 1, databaseID: 1, strings: [.title: title, .album: album], duration: 0, fileSize: 0,
                    trackNumber: trackNumber, trackCount: 0, discNumber: 1, discCount: 1, year: 0, bitrate: 0,
                    sampleRate: 0, rating: 0, playCount: 0, mediaType: 1,
                    dateAdded: nil, lastPlayed: nil, lastModified: nil)
    }

    private func sortedTitles(_ tracks: [ITunesTrack], by sortType: LibraryIndexSortType) -> [String] {
        let builder = LibraryIndexRecordBuilder(tracks: tracks)
        return builder.sortedPositions(tracks.map(sortType.sortKey(for:))).map { tracks[$0].title }
    }

    @Test func sortsTitlesIgnoringCaseAndDiacritics() {
        let tracks = ["banana", "Éclair", "Apple", "cherry", "42", "echo"].map { track($0) }
        #expect(sortedTitles(tracks, by: .title) == ["42", "Apple", "banana", "cherry", "echo", "Éclair"])
    }

    @Test func sortsAlbumsByTrackNumberNumerically() {
        let tracks = [track("Ten", album: "Hits", trackNumber: 10), track("Two", album: "Hits", trackNumber: 2)]
        #expect(sortedTitles(tracks, by: .album) == ["Two", "Ten"])
    }

    @Test func emitsIndexAndJumpTableForEverySortType() {
        let records = LibraryIndexRecordBuilder(tracks: [track("Apple"), track("avocado"), track("Banana")]).records()
        #expect(records.count == LibraryIndexSortType.allCases.count * 2)
        let titleJumpTable = records[1]
        guard case .opaque(let payload) = titleJumpTable.body else { Issue.record("Expected opaque mhod"); return }
        #expect(payload.read(UInt32.self, at: 0x04) == 2)
        #expect(payload.read(UInt32.self, at: 0x10) == UInt32(UInt8(ascii: "A")))
        #expect(payload.read(UInt32.self, at: 0x18) == 2)
        #expect(payload.read(UInt32.self, at: 0x1C) == UInt32(UInt8(ascii: "B")))
        #expect(payload.read(UInt32.self, at: 0x20) == 2)
    }

    @Test(arguments: [("", UInt16(0)), ("9 Lives", UInt16(UInt8(ascii: "0"))),
                      ("éclair", UInt16(UInt8(ascii: "E"))), ("zebra", UInt16(UInt8(ascii: "Z")))])
    func jumpLetters(key: String, letter: UInt16) {
        #expect(LibraryIndexRecordBuilder.jumpLetter(for: key) == letter)
    }
}
