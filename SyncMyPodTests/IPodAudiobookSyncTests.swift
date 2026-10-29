import Foundation
import Testing
@testable import SyncMyPod

struct IPodAudiobookSyncTests {
    private let fixture = ITunesDBFixtureBuilder(playlists: [FixturePlaylist(id: 1, name: "iPod", isMaster: true,
                                                                             trackIDs: [])],
                                                 includesAlbumSection: true, includesPodcastSection: true).build()

    private func part(_ name: String, in volume: TemporaryIPodVolume) throws -> SyncRequest {
        var draft = ITunesTrackDraft(title: name, artist: "Mary Shelley", album: "Frankenstein", fileSize: 1_024)
        draft.mediaKind = .audiobook
        return SyncRequest(sourceURL: try volume.makeSourceFile(named: name), draft: draft,
                               source: SyncSource(fileSize: 1_024, modificationDate: .distantPast,
                                                  artworkFingerprint: nil), kind: .audiobook)
    }

    private func list(_ section: ITunesDBSectionType, on volume: TemporaryIPodVolume) throws -> [ITunesDBRecord] {
        let root = try ITunesDBRecordParser(data: Data(contentsOf: volume.databaseURL)).parse()
        return root.children.first { $0.isSection(section) }?.children.first?.children ?? []
    }

    private func tracks(on volume: TemporaryIPodVolume) throws -> [ITunesDBRecord] {
        try list(.tracks, on: volume)
    }

    @Test func eachBookIsAnOrdinaryPlaylistOfItsPartsInOrder() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let parts = [try part("01.m4a", in: volume), try part("02.m4a", in: volume)]
        let book = SyncAudiobookSnapshot(key: "book", title: "Frankenstein", author: "Mary Shelley", files: parts,
                                         playlistID: 42, createdAt: .now)
        _ = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: parts, playlists: [book.playlist])

        for section in [ITunesDBSectionType.playlists, .podcasts] {
            let playlist = try #require(try list(section, on: volume).first { $0.uint64(at: 0x1C) == 42 })
            #expect(!ITunesDBPlaylistWriter.isPodcastList(playlist))
            #expect(playlist.children.filter { $0.tag == "mhip" }.count == 2)
        }
        let database = try ITunesDBParser(data: Data(contentsOf: volume.databaseURL)).parse()
        let playlist = try #require(database.playlists.first { $0.id == 42 })
        #expect(playlist.name == "Frankenstein")
        #expect(playlist.trackIDs.compactMap { id in database.tracks.first { $0.id == id }?.title } == ["01.m4a", "02.m4a"])
    }

    @Test func partsAreMarkedAsAudiobooksThatResumeAndSkipShuffle() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        _ = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: [try part("01.m4a", in: volume)])
        let mhit = try #require(try tracks(on: volume).first)
        #expect(mhit.uint32(at: 0xD0) == 8)
        #expect([0xA5, 0xA6, 0xA7].map { mhit.uint8(at: $0) } == [1, 1, 0])
        #expect(mhit.uint8(at: 0xB2) == 0)
        #expect(mhit.uint32(at: 0x18) == 0x4D34_4120)
    }

    @Test func m4bFilesKeepTheirExtensionAndFileType() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        _ = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: [try part("Book.m4b", in: volume)])
        let mhit = try #require(try tracks(on: volume).first)
        #expect(mhit.uint32(at: 0x18) == 0x4D34_4220)
        #expect(mhit.string(ofType: ITunesStringField.location.rawValue)?.lowercased().hasSuffix(".m4b") == true)
    }
}
