import Foundation
import Testing
@testable import SyncMyPod

struct ITunesDBPlaylistWriterTests {
    private let tracks = [
        FixtureTrack(id: 101, title: "Vertigo", artist: "U2", album: "Bomb", location: ":iPod_Control:Music:F00:A.m4a"),
        FixtureTrack(id: 102, title: "Clocks", artist: "Coldplay", album: "Rush", location: ":iPod_Control:Music:F01:B.m4a")
    ]

    private var fixture: Data {
        ITunesDBFixtureBuilder(tracks: tracks, playlists: [
            FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [101, 102]),
            FixturePlaylist(id: 2, name: "Favorites", trackIDs: [101])
        ], includesAlbumSection: true, includesPodcastSection: true).build()
    }

    private func draft(id: UInt64 = 77, name: String = "Road Trip", databaseIDs: [UInt64]) -> ITunesPlaylistDraft {
        ITunesPlaylistDraft(id: id, name: name, createdAt: .now, databaseIDs: databaseIDs)
    }

    private func replacing(_ drafts: [ITunesPlaylistDraft], removing ids: Set<UInt64> = [],
                           in data: Data) throws -> Data {
        var editor = try ITunesDBEditor(root: ITunesDBRecordParser(data: data).parse())
        editor.replacePlaylists(drafts, removing: ids)
        return try editor.serialized()
    }

    private func playlists(in data: Data, section: ITunesDBSectionType) throws -> [(name: String?, id: UInt64)] {
        let root = try ITunesDBRecordParser(data: data).parse()
        let list = try #require(root.children.first { $0.isSection(section) }?.children.first)
        return list.children.map { ($0.string(ofType: ITunesStringField.title.rawValue), $0.uint64(at: 0x1C)) }
    }

    @Test func writesThePlaylistWithItsSongsInOrder() throws {
        let data = try replacing([draft(databaseIDs: [102_000, 101_000])], in: fixture)
        let written = try #require(try ITunesDBParser(data: data).parse().playlists.first { $0.id == 77 })
        #expect(written.name == "Road Trip")
        #expect(!written.isMaster)
        #expect(written.trackIDs == [102, 101])
    }

    @Test func writesToBothPlaylistSections() throws {
        let data = try replacing([draft(databaseIDs: [101_000])], in: fixture)
        #expect(try playlists(in: data, section: .playlists).map(\.id) == [1, 2, 77])
        #expect(try playlists(in: data, section: .podcasts).map(\.id) == [1, 2, 77])
    }

    @Test func replacesAPlaylistWithTheSameID() throws {
        let first = try replacing([draft(databaseIDs: [101_000])], in: fixture)
        let second = try replacing([draft(name: "Renamed", databaseIDs: [102_000])], in: first)
        let written = try ITunesDBParser(data: second).parse().userPlaylists
        #expect(written.map(\.name) == ["Favorites", "Renamed"])
        #expect(written.last?.trackIDs == [102])
    }

    @Test func removesOnlyTheGivenPlaylists() throws {
        let first = try replacing([draft(databaseIDs: [101_000])], in: fixture)
        let second = try replacing([], removing: [77], in: first)
        let database = try ITunesDBParser(data: second).parse()
        #expect(database.playlists.map(\.name) == ["iPod", "Favorites"])
        #expect(database.masterPlaylist?.trackIDs == [101, 102])
    }

    @Test func leavesOutSongsNotOnTheIPod() throws {
        let data = try replacing([draft(databaseIDs: [101_000, 999])], in: fixture)
        #expect(try ITunesDBParser(data: data).parse().userPlaylists.last?.trackIDs == [101])
    }

    @Test func givesEntriesFreshItemIDs() throws {
        let data = try replacing([draft(databaseIDs: [101_000, 102_000])], in: fixture)
        let root = try ITunesDBRecordParser(data: data).parse()
        let list = try #require(root.children.first { $0.isSection(.playlists) }?.children.first)
        let written = try #require(list.children.first { $0.uint64(at: 0x1C) == 77 })
        let itemIDs = written.children.filter { $0.tag == "mhip" }.map { $0.uint32(at: 0x14) }
        #expect(itemIDs.count == 2 && Set(itemIDs).count == 2)
        #expect(itemIDs.allSatisfy { $0 > 102 })
    }
}
