import Foundation
import Testing
@testable import SyncMyPod

struct ITunesDBTrackRemoverTests {
    private let vertigo = FixtureTrack(id: 101, title: "Vertigo", artist: "U2", album: "Bomb",
                                       location: ":iPod_Control:Music:F07:ABCD.m4a")
    private let clocks = FixtureTrack(id: 102, title: "Clocks", artist: "Coldplay", album: "A Rush",
                                      location: ":iPod_Control:Music:F12:EFGH.m4a")

    private var fixture: Data {
        ITunesDBFixtureBuilder(tracks: [vertigo, clocks], playlists: [
            FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [101, 102]),
            FixturePlaylist(id: 2, name: "Favorites", trackIDs: [102, 101])
        ], includesAlbumSection: true, includesPodcastSection: true).build()
    }

    private func removing(_ databaseIDs: Set<UInt64>, from data: Data) throws -> (data: Data, locations: [String]) {
        var editor = try ITunesDBEditor(root: ITunesDBRecordParser(data: data).parse())
        let locations = editor.removeTracks(databaseIDs: databaseIDs)
        return (try editor.serialized(), locations)
    }

    @Test func removesTrackFromTrackListAndEveryPlaylist() throws {
        let result = try removing([102_000], from: fixture)
        let database = try ITunesDBParser(data: result.data).parse()
        #expect(result.locations == [":iPod_Control:Music:F12:EFGH.m4a"])
        #expect(database.tracks.map(\.title) == ["Vertigo"])
        #expect(database.masterPlaylist?.trackIDs == [101])
        #expect(database.userPlaylists.first?.trackIDs == [101])
    }

    @Test func updatesItemCountsInBothPlaylistSections() throws {
        let root = try ITunesDBRecordParser(data: removing([102_000], from: fixture).data).parse()
        for section in [ITunesDBSectionType.playlists, .podcasts] {
            let playlists = try #require(root.children.first { $0.isSection(section) }?.children.first).children
            for playlist in playlists {
                #expect(playlist.uint32(at: 0x10) == UInt32(playlist.children.filter { $0.tag == "mhip" }.count))
            }
        }
    }

    @Test func ignoresUnknownDatabaseIDs() throws {
        let result = try removing([42], from: fixture)
        #expect(result.locations.isEmpty)
        #expect(result.data == fixture)
    }

    @Test func prunesAlbumEntriesNoTrackUses() throws {
        var editor = try ITunesDBEditor(root: ITunesDBRecordParser(data: fixture).parse())
        let keep = editor.addTrack(ITunesTrackDraft(title: "One", album: "Shared", location: ":a"))
        let drop = editor.addTrack(ITunesTrackDraft(title: "Two", album: "Shared", location: ":b"))
        let lone = editor.addTrack(ITunesTrackDraft(title: "Three", album: "Lonely", location: ":c"))
        _ = editor.removeTracks(databaseIDs: [drop, lone])
        let root = try ITunesDBRecordParser(data: editor.serialized()).parse()
        let albums = try #require(root.children.first { $0.isSection(.albums) }?.children.first).children
        #expect(albums.compactMap { $0.string(ofType: AlbumItemRecordBuilder.albumType) } == ["Shared"])
        #expect(try ITunesDBParser(data: editor.serialized()).parse().tracks.map(\.databaseID).contains(keep))
    }

    @Test(.enabled(if: RealDeviceFixture.data != nil, "No real iTunesDB fixture present"))
    func removesTheOnlyTrackFromRealDatabase() throws {
        let original = try #require(RealDeviceFixture.data)
        let track = try #require(try ITunesDBParser(data: original).parse().tracks.first)
        let data = try removing([track.databaseID], from: original).data
        let database = try ITunesDBParser(data: data).parse()
        #expect(database.tracks.isEmpty)
        #expect(database.masterPlaylist?.trackIDs.isEmpty == true)
        #expect(try ITunesDBRecordParser(data: data).parse().serialized() == data)
    }
}
