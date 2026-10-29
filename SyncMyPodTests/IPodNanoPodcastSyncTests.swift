import Foundation
import Testing
@testable import SyncMyPod

struct IPodNanoPodcastSyncTests {
    private static let nanoID = "000A27002487F3F7"
    private static let released = Date(timeIntervalSince1970: 1_792_047_600)
    private let signer = HashAB(fireWireID: FireWireID(hexString: nanoID)!)

    private func nano(on volume: TemporaryIPodVolume) -> IPodDevice {
        var device = IPodDevice(id: "1", volumeURL: volume.url, volumeName: "NANO", capacityBytes: nil, availableBytes: nil,
                                sysInfo: .empty, usbIdentity: IPodUSBIdentity(vendorString: "Apple", productString: "iPod",
                                                                              serialNumber: Self.nanoID, vendorID: 0x05AC,
                                                                              productID: 0x1267))
        device.libraryCommands = NanoPostProcessCommands(version: 26, statements: [])
        return device
    }

    /// A signed iTunesCDB with only the podcast-aware playlist section, as iTunes writes it for a nano.
    private func nanoVolume() throws -> TemporaryIPodVolume {
        let database = ITunesDBFixtureBuilder(playlists: [FixturePlaylist(id: 1, name: "iPod", isMaster: true,
                                                                          trackIDs: [])],
                                              includesAlbumSection: true, databaseHeaderLength: 0xF4).build()
        let volume = try TemporaryIPodVolume(database: nil)
        try signer.sign(try ITunesCDB.compress(database)).write(to: ITunesDBLoader.compressedDatabaseURL(onVolume: volume.url))
        return volume
    }

    private func episode(in volume: TemporaryIPodVolume) throws -> SyncRequest {
        let source = try AudioFixtureWriter.writeSilence(to: volume.url.appending(path: "source/Episode.m4a"))
        var draft = TrackTags(title: "Episode", album: "Show", fileSize: try Data(contentsOf: source).count)
        draft.releaseDate = Self.released
        return SyncRequest(sourceURL: source, tags: draft,
                               source: SyncSource(fileSize: draft.fileSize, modificationDate: .distantPast,
                                                  artworkFingerprint: nil), kind: .podcast)
    }

    private func library(_ volume: TemporaryIPodVolume) throws -> SQLiteConnection {
        try SQLiteConnection(openingAt: NanoLibraryInstaller(volumeURL: volume.url).folderURL
            .appending(path: NanoLibraryFile.library.fileName))
    }

    @Test func episodesArePodcastsInTheNanosLibrary() async throws {
        let volume = try nanoVolume()
        let episode = try episode(in: volume)
        let podcasts = SyncPlaylistRequest(id: SyncPlaylistRequest.podcastsID, name: "Podcasts", createdAt: .now,
                                           tracks: [episode], isPodcasts: true)
        _ = try await IPodTrackSyncer(device: nano(on: volume)).sync(adding: [episode], playlists: [podcasts])

        let library = try library(volume)
        #expect(try library.rows("SELECT media_kind, is_podcast, is_song, remember_bookmark, exclude_from_shuffle FROM item")
                == [[.integer(4), .integer(1), .integer(0), .integer(1), .integer(1)]])
        #expect(try library.rows("SELECT date_released FROM podcast_info")
                == [[.integer(Int64(Self.released.timeIntervalSinceReferenceDate))]])
        #expect(try library.rows("SELECT name, media_kinds, is_hidden FROM container WHERE distinguished_kind = 0 "
                                 + "AND pid != (SELECT primary_container_pid FROM db_info)")
                == [[.text("Podcasts"), .integer(4), .integer(0)]])
        #expect(try library.rows("SELECT count(*) FROM item_to_container JOIN container ON container.pid = container_pid "
                                 + "WHERE name = 'Podcasts'") == [[.integer(1)]])
    }

    @Test func audiobookPartsAreAudiobooksInTheNanosLibrary() async throws {
        let volume = try nanoVolume()
        let source = try AudioFixtureWriter.writeSilence(to: volume.url.appending(path: "source/01.m4a"))
        let draft = TrackTags(title: "Letters", album: "Frankenstein", fileSize: try Data(contentsOf: source).count)
        let part = SyncRequest(sourceURL: source, tags: draft,
                                   source: SyncSource(fileSize: draft.fileSize, modificationDate: .distantPast,
                                                      artworkFingerprint: nil), kind: .audiobook)
        let book = SyncAudiobookSnapshot(key: "book", title: "Frankenstein", author: "", files: [part],
                                         playlistID: 42, createdAt: .now)
        _ = try await IPodTrackSyncer(device: nano(on: volume)).sync(adding: [part], playlists: [book.playlist])

        let library = try library(volume)
        #expect(try library.rows("SELECT media_kind, is_audio_book, is_song, is_podcast, remember_bookmark, "
                                 + "exclude_from_shuffle FROM item")
                == [[.integer(8), .integer(1), .integer(0), .integer(0), .integer(1), .integer(1)]])
        #expect(try library.rows("SELECT media_kinds, is_hidden FROM container WHERE name = 'Frankenstein'")
                == [[.integer(8), .integer(0)]])
        #expect(try library.rows("SELECT count(*) FROM item_to_container JOIN container ON container.pid = container_pid "
                                 + "WHERE name = 'Frankenstein'") == [[.integer(1)]])
    }

    @Test func theNanosGroupedPodcastsListReadsAsItsEpisodes() async throws {
        let volume = try nanoVolume()
        let episode = try episode(in: volume)
        let podcasts = SyncPlaylistRequest(id: SyncPlaylistRequest.podcastsID, name: "Podcasts", createdAt: .now,
                                           tracks: [episode], isPodcasts: true)
        _ = try await IPodTrackSyncer(device: nano(on: volume)).sync(adding: [episode], playlists: [podcasts])

        let data = try ITunesCDB.decompress(Data(contentsOf: ITunesDBLoader.compressedDatabaseURL(onVolume: volume.url)))
        let database = try ITunesDBParser(data: data).parse()
        let list = try #require(database.playlists.first { $0.id == SyncPlaylistRequest.podcastsID })
        #expect(list.trackIDs == database.tracks.map(\.id))
    }
}
