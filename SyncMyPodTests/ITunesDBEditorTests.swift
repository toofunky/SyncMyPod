import Foundation
import Testing
@testable import SyncMyPod

struct ITunesDBEditorTests {
    private let vertigo = FixtureTrack(id: 101, title: "Vertigo", artist: "U2",
                                       album: "How to Dismantle an Atomic Bomb",
                                       location: ":iPod_Control:Music:F07:ABCD.m4a")
    private let clocks = ITunesTrackDraft(title: "Clocks", artist: "Coldplay", album: "A Rush of Blood to the Head",
                                          genre: "Rock", location: ":iPod_Control:Music:F01:WXYZ.m4a",
                                          fileSize: 7_000_000, duration: 307.2, trackNumber: 5, trackCount: 11,
                                          discNumber: 1, discCount: 1, year: 2002, bitrate: 256, sampleRate: 44_100)

    private var fixture: Data {
        ITunesDBFixtureBuilder(tracks: [vertigo], playlists: [
            FixturePlaylist(id: 1, name: "Michael's iPod", isMaster: true, trackIDs: [101]),
            FixturePlaylist(id: 2, name: "Favorites", trackIDs: [101])
        ], includesAlbumSection: true, includesPodcastSection: true).build()
    }

    private func adding(_ drafts: [ITunesTrackDraft], to data: Data) throws -> (data: Data, ids: [UInt64]) {
        var editor = try ITunesDBEditor(root: ITunesDBRecordParser(data: data).parse())
        let ids = drafts.map { editor.addTrack($0) }
        return (try editor.serialized(), ids)
    }

    private func masterPlaylist(in data: Data, section: ITunesDBSectionType) throws -> ITunesDBRecord {
        let root = try ITunesDBRecordParser(data: data).parse()
        let list = try #require(root.children.first { $0.isSection(section) }?.children.first)
        return try #require(list.children.first { $0.isMasterPlaylist })
    }

    private func indexEntries(in playlist: ITunesDBRecord, sortType: LibraryIndexSortType) throws -> [UInt32] {
        let payloads = playlist.children.compactMap { mhod -> Data? in
            guard mhod.recordType == LibraryIndexRecordBuilder.indexType,
                  case .opaque(let payload) = mhod.body else { return nil }
            return payload
        }
        let payload = try #require(payloads.first { $0.read(UInt32.self, at: 0x00) == sortType.rawValue })
        return (0..<Int(payload.read(UInt32.self, at: 0x04))).map { payload.read(UInt32.self, at: 0x30 + $0 * 4) }
    }

    @Test func unchangedEditorSerializesByteForByte() throws {
        #expect(try adding([], to: fixture).data == fixture)
    }

    @Test func addedTrackReadsBackWithItsMetadata() throws {
        let result = try adding([clocks], to: fixture)
        let tracks = try ITunesDBParser(data: result.data).parse().tracks
        try #require(tracks.count == 2)
        let track = tracks[1]
        #expect(track.title == "Clocks" && track.artist == "Coldplay" && track.genre == "Rock")
        #expect(track.album == "A Rush of Blood to the Head")
        #expect(track.location == ":iPod_Control:Music:F01:WXYZ.m4a")
        #expect(track.strings[.fileType] == "AAC audio file")
        #expect(track.duration == 307.2 && track.fileSize == 7_000_000)
        #expect(track.trackNumber == 5 && track.trackCount == 11 && track.discNumber == 1)
        #expect(track.year == 2002 && track.bitrate == 256 && track.sampleRate == 44_100)
        #expect(track.mediaType == 1)
        #expect(track.databaseID == result.ids[0])
        #expect(track.id > vertigo.id)
    }

    @Test(arguments: [(AudioCodec.aac, "AAC audio file", 0x4D34_4120 as UInt32, 0x33 as UInt16),
                      (.alac, "Apple Lossless audio file", 0x4D34_4120, 0x33),
                      (.mp3, "MPEG audio file", 0x4D50_3320, 0x0C)])
    func addedTrackDescribesItsCodec(codec: AudioCodec, kind: String, fileType: UInt32, marker: UInt16) throws {
        var draft = clocks
        draft.codec = codec
        let root = try ITunesDBRecordParser(data: adding([draft], to: fixture).data).parse()
        let mhit = try #require(root.children.first { $0.isSection(.tracks) }?.children.first?.children.last)
        #expect(mhit.string(ofType: ITunesStringField.fileType.rawValue) == kind)
        #expect(mhit.uint32(at: 0x18) == fileType)
        #expect(mhit.header.read(UInt16.self, at: 0x90) == marker)
    }

    @Test func addedTrackJoinsOnlyTheMasterPlaylist() throws {
        let database = try ITunesDBParser(data: adding([clocks], to: fixture).data).parse()
        let newID = try #require(database.tracks.last?.id)
        #expect(database.masterPlaylist?.trackIDs == [101, newID])
        #expect(database.userPlaylists.first?.trackIDs == [101])
    }

    @Test(arguments: [ITunesDBSectionType.playlists, .podcasts])
    func addedTrackAppearsInBothPlaylistSections(section: ITunesDBSectionType) throws {
        let master = try masterPlaylist(in: adding([clocks], to: fixture).data, section: section)
        #expect(master.uint32(at: 0x10) == 2)
        #expect(master.children.filter { $0.tag == "mhip" }.count == 2)
    }

    @Test func tracksOnTheSameAlbumShareOneAlbumListEntry() throws {
        var secondClocksTrack = clocks
        secondClocksTrack.title = "The Scientist"
        let data = try adding([clocks, secondClocksTrack], to: fixture).data
        let root = try ITunesDBRecordParser(data: data).parse()
        let albums = try #require(root.children.first { $0.isSection(.albums) }?.children.first)
        let tracks = try #require(root.children.first { $0.isSection(.tracks) }?.children.first)
        #expect(albums.children.count == 1)
        #expect(albums.children.first?.string(ofType: AlbumItemRecordBuilder.albumType) == clocks.album)
        #expect(tracks.children[1].uint32(at: 0x120) == albums.children[0].uint32(at: 0x10))
        #expect(tracks.children[2].uint32(at: 0x120) == albums.children[0].uint32(at: 0x10))
    }

    @Test func rebuildsMasterPlaylistBrowseIndexes() throws {
        let master = try masterPlaylist(in: adding([clocks], to: fixture).data, section: .playlists)
        let mhods = master.children.filter { $0.tag == "mhod" }
        #expect(master.uint32(at: 0x0C) == UInt32(mhods.count))
        #expect(mhods.filter { $0.recordType == LibraryIndexRecordBuilder.indexType }.count == 5)
        #expect(mhods.filter { $0.recordType == LibraryIndexRecordBuilder.jumpTableType }.count == 5)
        #expect(try indexEntries(in: master, sortType: .title) == [1, 0])
        #expect(try indexEntries(in: master, sortType: .artist) == [1, 0])
    }

    @Test func linksTrackToItsArtwork() throws {
        var withArtwork = clocks
        withArtwork.artwork = ITunesTrackArtwork(imageID: 101, sourceByteCount: 54_321)
        let data = try adding([withArtwork, clocks], to: fixture).data
        let tracks = try #require(ITunesDBRecordParser(data: data).parse().children.first { $0.isSection(.tracks) })
        let linked = tracks.children[0].children[1]
        let plain = tracks.children[0].children[2]
        #expect(linked.uint8(at: 0xA4) == 1 && plain.uint8(at: 0xA4) == 2)
        #expect(linked.uint32(at: 0x160) == 101 && plain.uint32(at: 0x160) == 0)
        #expect(linked.header.read(UInt16.self, at: 0x7C) == 1)
        #expect(linked.uint32(at: 0x80) == 54_321)
    }

    @Test func rejectsDatabaseWithoutMasterPlaylist() throws {
        let data = ITunesDBFixtureBuilder(tracks: [vertigo]).build()
        #expect(throws: IPodSyncError.missingMasterPlaylist) {
            try ITunesDBEditor(root: ITunesDBRecordParser(data: data).parse())
        }
    }

    @Test(.enabled(if: RealDeviceFixture.data != nil, "No real iTunesDB fixture present"))
    func addsTrackToRealDatabase() throws {
        let original = try #require(RealDeviceFixture.data)
        let before = try ITunesDBParser(data: original).parse()
        let data = try adding([clocks], to: original).data
        let after = try ITunesDBParser(data: data).parse()
        #expect(after.tracks.count == before.tracks.count + 1)
        #expect(after.masterPlaylist?.trackIDs.count == before.tracks.count + 1)
        #expect(after.userPlaylists.map(\.trackIDs) == before.userPlaylists.map(\.trackIDs))
        #expect(try ITunesDBRecordParser(data: data).parse().serialized() == data)
    }
}
