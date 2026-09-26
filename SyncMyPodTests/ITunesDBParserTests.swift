import Foundation
import Testing
@testable import SyncMyPod

struct ITunesDBParserTests {
    private let vertigo = FixtureTrack(id: 101, title: "Vertigo", artist: "U2",
                                       album: "How to Dismantle an Atomic Bomb",
                                       location: ":iPod_Control:Music:F07:ABCD.mp3",
                                       durationMilliseconds: 194_000, playCount: 42,
                                       dateAddedMacSeconds: 3_214_080_000)
    private let clocks = FixtureTrack(id: 102, title: "Clocks", artist: "Coldplay",
                                      album: "A Rush of Blood to the Head",
                                      location: ":iPod_Control:Music:F12:EFGH.m4a")

    @Test func parsesDatabaseHeader() throws {
        let database = try ITunesDBParser(data: ITunesDBFixtureBuilder().build()).parse()
        #expect(database.version == 0x19)
        #expect(database.databaseID == 0x0123_4567_89AB_CDEF)
        #expect(database.tracks.isEmpty)
    }

    @Test func parsesTrackStringsAndNumbers() throws {
        let data = ITunesDBFixtureBuilder(tracks: [vertigo, clocks]).build()
        let tracks = try ITunesDBParser(data: data).parse().tracks
        try #require(tracks.count == 2)
        #expect(tracks[0].id == 101)
        #expect(tracks[0].databaseID == 101_000)
        #expect(tracks[0].title == "Vertigo")
        #expect(tracks[0].artist == "U2")
        #expect(tracks[0].location == ":iPod_Control:Music:F07:ABCD.mp3")
        #expect(tracks[0].duration == 194)
        #expect(tracks[0].playCount == 42)
        #expect(tracks[0].sampleRate == 44_100)
        #expect(tracks[0].rating == 80)
        #expect(tracks[0].mediaType == 1)
        #expect(tracks[0].dateAdded == Date(timeIntervalSince1970: 3_214_080_000 - 2_082_844_800))
        #expect(tracks[1].title == "Clocks")
    }

    @Test func decodesUTF8Strings() throws {
        let track = FixtureTrack(id: 1, title: "Björk – Jóga", artist: "Björk", album: "Homogenic",
                                 location: ":iPod_Control:Music:F00:JOGA.mp3")
        let data = ITunesDBFixtureBuilder(tracks: [track], usesUTF8Strings: true).build()
        #expect(try ITunesDBParser(data: data).parse().tracks.first?.title == "Björk – Jóga")
    }

    @Test func parsesPlaylistsAndSkipsNonStringRecords() throws {
        let builder = ITunesDBFixtureBuilder(tracks: [vertigo, clocks], playlists: [
            FixturePlaylist(id: 1, name: "Michael's iPod", isMaster: true, trackIDs: [101, 102]),
            FixturePlaylist(id: 2, name: "Favorites", trackIDs: [102])
        ])
        let database = try ITunesDBParser(data: builder.build()).parse()
        #expect(database.masterPlaylist?.name == "Michael's iPod")
        #expect(database.masterPlaylist?.trackIDs == [101, 102])
        #expect(database.userPlaylists.map(\.name) == ["Favorites"])
        #expect(database.userPlaylists.first?.trackIDs == [102])
    }

    @Test func skipsUnhandledSections() throws {
        let data = ITunesDBFixtureBuilder(tracks: [vertigo], includesAlbumSection: true).build()
        #expect(try ITunesDBParser(data: data).parse().tracks.count == 1)
    }

    @Test func rejectsDataThatIsNotAnITunesDB() {
        #expect(throws: ITunesDBError.unexpectedTag(expected: "mhbd", found: "junk", offset: 0)) {
            try ITunesDBParser(data: Data("junk data here".utf8)).parse()
        }
    }

    @Test func rejectsTruncatedDatabase() {
        let data = ITunesDBFixtureBuilder(tracks: [vertigo, clocks]).build()
        #expect(throws: ITunesDBError.self) {
            try ITunesDBParser(data: data.prefix(data.count - 10)).parse()
        }
    }
}
