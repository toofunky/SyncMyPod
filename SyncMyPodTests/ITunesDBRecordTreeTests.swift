import Foundation
import Testing
@testable import SyncMyPod

struct ITunesDBRecordTreeTests {
    private let vertigo = FixtureTrack(id: 101, title: "Vertigo", artist: "U2",
                                       album: "How to Dismantle an Atomic Bomb",
                                       location: ":iPod_Control:Music:F07:ABCD.mp3")
    private let clocks = FixtureTrack(id: 102, title: "Clocks", artist: "Coldplay",
                                      album: "A Rush of Blood to the Head",
                                      location: ":iPod_Control:Music:F12:EFGH.m4a")

    private var fullBuilder: ITunesDBFixtureBuilder {
        ITunesDBFixtureBuilder(tracks: [vertigo, clocks], playlists: [
            FixturePlaylist(id: 1, name: "Michael's iPod", isMaster: true, trackIDs: [101, 102]),
            FixturePlaylist(id: 2, name: "Favorites", trackIDs: [102])
        ], includesAlbumSection: true, includesRawSection: true)
    }

    @Test func roundTripsFixtureByteForByte() throws {
        let data = fullBuilder.build()
        #expect(try ITunesDBRecordParser(data: data).parse().serialized() == data)
    }

    @Test(.enabled(if: RealDeviceFixture.data != nil, "No real iTunesDB fixture present"))
    func roundTripsRealDatabaseByteForByte() throws {
        let data = try #require(RealDeviceFixture.data)
        #expect(try ITunesDBRecordParser(data: data).parse().serialized() == data)
    }

    @Test func preservesUnparsedSectionContentAsTrailer() throws {
        let root = try ITunesDBRecordParser(data: fullBuilder.build()).parse()
        let rawSection = try #require(root.children.last)
        #expect(rawSection.children.isEmpty)
        #expect(rawSection.body == .container([], trailer: Data("13b7d9f0c2a4e6f8".utf8)))
    }

    @Test func propagatesLengthsAfterAddingATrack() throws {
        var root = try ITunesDBRecordParser(data: ITunesDBFixtureBuilder(tracks: [vertigo]).build()).parse()
        let trackSection = try #require(root.children.firstIndex { $0.header[0x0C] == 1 })
        let track = try #require(root.children[trackSection].children.first?.children.first)
        root.children[trackSection].children[0].children.append(track)

        let serialized = root.serialized()
        #expect(try ITunesDBParser(data: serialized).parse().tracks.count == 2)
        #expect(try ITunesDBRecordParser(data: serialized).parse().serialized() == serialized)
    }

    @Test func rejectsTruncatedDatabase() {
        let data = fullBuilder.build()
        #expect(throws: ITunesDBError.self) {
            try ITunesDBRecordParser(data: data.prefix(data.count - 10)).parse()
        }
    }

    @Test func rejectsTrailingBytesAfterRoot() {
        #expect(throws: ITunesDBError.invalidLength(offset: 0)) {
            try ITunesDBRecordParser(data: fullBuilder.build() + Data(count: 4)).parse()
        }
    }
}
