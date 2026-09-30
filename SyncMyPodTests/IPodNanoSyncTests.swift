import Foundation
import Testing
@testable import SyncMyPod

struct IPodNanoSyncTests {
    private static let nanoID = "000A27002487F3F7"
    private let signer = HashAB(fireWireID: FireWireID(hexString: nanoID)!)
    private let commands = NanoPostProcessCommands(version: 26, statements: [
        "ALTER TABLE album ADD COLUMN has_songs INTEGER DEFAULT 0",
        "UPDATE album SET has_songs = 1"
    ])

    private func device(volume: URL, commands: NanoPostProcessCommands?) -> IPodDevice {
        var device = IPodDevice(id: "1", volumeURL: volume, volumeName: "NANO", capacityBytes: nil, availableBytes: nil,
                                sysInfo: .empty, usbIdentity: IPodUSBIdentity(vendorString: "Apple", productString: "iPod",
                                                                              serialNumber: Self.nanoID, vendorID: 0x05AC,
                                                                              productID: 0x1267))
        device.libraryCommands = commands
        return device
    }

    /// A volume holding a signed iTunesCDB with only the podcast-aware playlist section, as iTunes writes it.
    private func nanoVolume() throws -> TemporaryIPodVolume {
        let database = ITunesDBFixtureBuilder(playlists: [FixturePlaylist(id: 1, name: "iPod", isMaster: true,
                                                                          trackIDs: [])],
                                              includesAlbumSection: true, databaseHeaderLength: 0xF4).build()
        let volume = try TemporaryIPodVolume(database: nil)
        try signer.sign(try ITunesCDB.compress(database)).write(to: cdbURL(volume))
        return volume
    }

    private func cdbURL(_ volume: TemporaryIPodVolume) -> URL {
        ITunesDBLoader.compressedDatabaseURL(onVolume: volume.url)
    }

    private func song(_ title: String, in volume: TemporaryIPodVolume) throws -> IPodSyncRequest {
        let source = try AudioFixtureWriter.writeSilence(to: volume.url.appending(path: "source/\(title).m4a"))
        return IPodSyncRequest(sourceURL: source, draft: ITunesTrackDraft(title: title, album: "Album",
                                                                          fileSize: try Data(contentsOf: source).count))
    }

    private func coveredSong(in volume: TemporaryIPodVolume) async throws -> IPodSyncRequest {
        let silence = try AudioFixtureWriter.writeSilence(to: volume.url.appending(path: "source/plain.m4a"))
        let source = volume.url.appending(path: "source/covered.m4a")
        let cover = TestImage.make(width: 500, height: 500, top: TestImage.color(1, 0, 0))
        try await AudioFixtureWriter.embedCoverArt(TestImage.pngData(cover), from: silence, to: source)
        return IPodSyncRequest(sourceURL: source, draft: ITunesTrackDraft(title: "Song", album: "Album",
                                                                          fileSize: try Data(contentsOf: source).count))
    }

    private func library(_ volume: TemporaryIPodVolume, _ file: NanoLibraryFile = .library) throws -> SQLiteConnection {
        try SQLiteConnection(openingAt: NanoLibraryInstaller(volumeURL: volume.url).folderURL.appending(path: file.fileName))
    }

    /// The sizes a nano 7G's own ArtworkDB declares for its four cover formats.
    @Test func nanoArtworkMatchesTheSizesTheDeviceDeclares() {
        #expect(ArtworkFormat.nano7G.map(\.id) == [1013, 1016, 1015, 1010])
        #expect(ArtworkFormat.nano7G.map(\.byteCount) == [5_000, 6_612, 6_728, 115_200])
    }

    @Test func nanosAreRefusedWithoutTheirLibraryCommands() throws {
        #expect(throws: IPodSyncError.missingLibraryCommands) {
            _ = try IPodTrackSyncer(device: device(volume: URL(filePath: "/Volumes/NANO"), commands: nil))
        }
    }

    @Test func syncWritesASignedCompressedDatabaseAndTheSQLiteLibrary() async throws {
        let volume = try nanoVolume()
        let syncer = try IPodTrackSyncer(device: device(volume: volume.url, commands: commands))
        _ = try await syncer.sync(adding: [try await coveredSong(in: volume)])

        let written = try Data(contentsOf: cdbURL(volume))
        #expect(ITunesCDB.isCompressed(written) && signer.isValid(written))
        #expect(try ITunesDBParser(data: ITunesCDB.decompress(written)).parse().tracks.map(\.title) == ["Song"])
        #expect(!FileManager.default.fileExists(atPath: volume.databaseURL.path(percentEncoded: false)))
        #expect(try library(volume).rows("SELECT title, album FROM item") == [[.text("Song"), .text("Album")]])
        #expect(try library(volume).rows("SELECT has_songs FROM album") == [[.integer(1)]])
        #expect(try library(volume).rows("PRAGMA user_version") == [[.integer(26)]])
        let folder = NanoLibraryInstaller(volumeURL: volume.url).folderURL
        #expect(LocationsChecksumBook.isValid(try Data(contentsOf: folder.appending(path: LocationsChecksumBook.fileName)),
                                              for: try Data(contentsOf: folder.appending(path: "Locations.itdb")),
                                              signer: signer))
        for format in ArtworkFormat.nano7G {
            let ithmb = volume.url.appending(path: "iPod_Control/Artwork/\(format.fileName)")
            #expect(try Data(contentsOf: ithmb).count == format.byteCount)
        }
        #expect(try library(volume).rows("SELECT artwork_status, artwork_cache_id > 0 FROM item") == [[.integer(1), .integer(1)]])
    }

    /// Adds a song to a copy of a real nano's iTunesCDB and library, then checks nothing about the existing
    /// tracks changed.
    @Test(.enabled(if: RealDeviceFixture.compressedDatabase != nil && RealDeviceFixture.nanoLibraryFolder != nil
                   && RealDeviceFixture.nanoSysInfoExtended != nil, "No real nano fixtures present"))
    func addingASongToARealNanoLeavesItsLibraryIntact() async throws {
        let volume = try TemporaryIPodVolume(database: nil)
        try #require(RealDeviceFixture.compressedDatabase).write(to: cdbURL(volume))
        let folder = NanoLibraryInstaller(volumeURL: volume.url).folderURL
        try FileManager.default.copyItem(at: try #require(RealDeviceFixture.nanoLibraryFolder), to: folder)
        let commands = NanoPostProcessCommands(sysInfoExtended: RealDeviceFixture.nanoSysInfoExtended ?? "")
        var nano = IPodDevice(id: "1", volumeURL: volume.url, volumeName: "NANO", capacityBytes: nil, availableBytes: nil,
                          sysInfo: .empty, usbIdentity: IPodUSBIdentity(vendorString: "Apple", productString: "iPod",
                                                                        serialNumber: RealDeviceFixture.compressedDatabaseFireWireID,
                                                                        vendorID: 0x05AC, productID: 0x1267))
        nano.libraryCommands = commands
        _ = try await IPodTrackSyncer(device: nano).sync(adding: [try song("Zzyzx Road", in: volume)])

        let columns = "pid, title, artist, album, album_pid, artist_pid, total_time_ms, "
            + "(SELECT genre FROM genre_map WHERE id = genre_id), (SELECT name FROM composer WHERE pid = composer_pid)"
        let before = try SQLiteConnection(openingAt: try #require(RealDeviceFixture.nanoLibraryFolder)
            .appending(path: "Library.itdb")).rows("SELECT \(columns) FROM item ORDER BY pid")
        let after = try library(volume).rows("SELECT \(columns) FROM item WHERE title != 'Zzyzx Road' ORDER BY pid")
        #expect(after == before)
        #expect(try library(volume).rows("SELECT count(*) FROM item") == [[.integer(Int64(before.count + 1))]])
        let stats = "SELECT item_pid, play_count_user, user_rating FROM item_stats ORDER BY item_pid"
        let statsBefore = try SQLiteConnection(openingAt: try #require(RealDeviceFixture.nanoLibraryFolder)
            .appending(path: "Dynamic.itdb")).rows(stats)
        #expect(try library(volume, .dynamic).rows(stats).filter { statsBefore.map(\.first).contains($0.first) } == statsBefore)
        #expect(try library(volume).rows("SELECT count(*) FROM container") == [[.integer(32)]])
    }

    @Test(.enabled(if: RealDeviceFixture.nanoArtworkDB != nil, "No real nano ArtworkDB fixture present"))
    func addsCoversToTheNanosOwnArtworkDB() async throws {
        let volume = try nanoVolume()
        let artworkURL = volume.url.appending(path: "iPod_Control/Artwork/ArtworkDB")
        try FileManager.default.createDirectory(at: artworkURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try #require(RealDeviceFixture.nanoArtworkDB).write(to: artworkURL)
        let syncer = try IPodTrackSyncer(device: device(volume: volume.url, commands: commands))
        _ = try await syncer.sync(adding: [try await coveredSong(in: volume)])

        let root = try ITunesDBRecordParser(data: Data(contentsOf: artworkURL), layout: .artworkDB).parse()
        let lists = root.children.map { $0.children.first?.children ?? [] }
        let files = lists[2].map { ($0.uint32(at: 0x10), $0.uint32(at: 0x14)) }
        #expect(files.map(\.0) == [1010, 1013, 1015, 1016])
        #expect(files.map(\.1) == [115_200, 5_000, 6_728, 6_612])
        let thumbnails = lists[0].flatMap(\.children).flatMap(\.children)
        #expect(Set(thumbnails.map { $0.uint32(at: 0x10) }) == [1010, 1013, 1015, 1016])
        #expect(thumbnails.first { $0.uint32(at: 0x10) == 1016 }.map { ($0.uint32(at: 0x18), $0.header.read(UInt16.self, at: 0x22)) }
            .map { $0 == (6_612, 57) } == true)
    }

    @Test func keepsPlayCountsTheNanoRecordedSinceTheLastSync() async throws {
        let volume = try nanoVolume()
        let syncer = try IPodTrackSyncer(device: device(volume: volume.url, commands: commands))
        _ = try await syncer.sync(adding: [try song("First", in: volume)])
        try library(volume, .dynamic).execute("UPDATE item_stats SET play_count_user = 5, has_been_played = 1")

        _ = try await syncer.sync(adding: [try song("Second", in: volume)])
        let counts = try library(volume, .dynamic).rows("SELECT play_count_user FROM item_stats ORDER BY play_count_user")
        #expect(counts == [[.integer(0)], [.integer(5)]])
    }
}
