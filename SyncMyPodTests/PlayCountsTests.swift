import Foundation
import Testing
@testable import SyncMyPod

struct PlayCountsTests {
    static func file(entries: [(plays: UInt32, lastPlayed: UInt32, rating: UInt32, skips: UInt32)]) -> Data {
        var data = Data(count: 0x60)
        data.replaceSubrange(0..<4, with: Data("mhdp".utf8))
        data.write(UInt32(0x60), at: 0x04)
        data.write(UInt32(0x1C), at: 0x08)
        data.write(UInt32(entries.count), at: 0x0C)
        for entry in entries {
            var record = Data(count: 0x1C)
            record.write(entry.plays, at: 0x00)
            record.write(entry.lastPlayed, at: 0x04)
            record.write(entry.rating, at: 0x0C)
            record.write(entry.skips, at: 0x14)
            data.append(record)
        }
        return data
    }

    @Test func parsesEntriesWithRatingsAndSkips() throws {
        let entries = try #require(PlayCountsFile.parse(Self.file(entries: [(3, 3_900_000_000, 80, 1)])))
        #expect(entries == [PlayCountEntry(playCount: 3, lastPlayed: 3_900_000_000, rating: 80, skipCount: 1)])
    }

    @Test func rejectsFilesThatAreNotPlayCounts() {
        #expect(PlayCountsFile.parse(Data("nope nope nope nope".utf8)) == nil)
        #expect(PlayCountsFile.parse(Self.file(entries: [(1, 0, 0, 0)]).dropLast(4)) == nil)
    }

    @Test func mergesIntoMatchingTracks() throws {
        let tracks = [FixtureTrack(id: 1, title: "A", artist: "", album: "", location: ":a", playCount: 5),
                      FixtureTrack(id: 2, title: "B", artist: "", album: "", location: ":b")]
        let data = ITunesDBFixtureBuilder(tracks: tracks, playlists: [
            FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [1, 2])
        ]).build()
        var editor = try ITunesDBEditor(root: ITunesDBRecordParser(data: data).parse())
        let entries = [PlayCountEntry(playCount: 2, rating: 100), PlayCountEntry()]
        let merged = editor.mergePlayCounts(entries)
        #expect(merged)
        let tracksAfter = try ITunesDBParser(data: editor.serialized()).parse().tracks
        #expect(tracksAfter.map(\.playCount) == [7, 0])
        #expect(tracksAfter[0].rating == 100)
        let mismatched = editor.mergePlayCounts([PlayCountEntry()])
        #expect(!mismatched)
    }

    @Test(.enabled(if: RealDeviceFixture.playCounts != nil && RealDeviceFixture.playCountsDatabase != nil,
                   "No real Play Counts fixture present"))
    func mergesRealPlayCountsIntoTheirDatabase() throws {
        let file = try #require(RealDeviceFixture.playCounts)
        let entries = try #require(PlayCountsFile.parse(file))
        let data = try #require(RealDeviceFixture.playCountsDatabase)
        let before = try ITunesDBParser(data: data).parse().tracks
        #expect(entries.count == before.count)

        var editor = try ITunesDBEditor(root: ITunesDBRecordParser(data: data).parse())
        let merged = editor.mergePlayCounts(entries)
        #expect(merged)
        let after = try ITunesDBParser(data: editor.serialized()).parse().tracks
        #expect(after.map(\.title) == before.map(\.title))
        #expect(zip(before, entries).map { $0.playCount + Int($1.playCount) } == after.map(\.playCount))
        let played = try #require(after.first { $0.title == "Forever Young" })
        #expect(played.playCount >= 1 && played.rating == 100 && played.lastPlayed != nil)
    }
}
