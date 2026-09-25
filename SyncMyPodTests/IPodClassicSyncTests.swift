import Foundation
import Testing
@testable import SyncMyPod

struct IPodClassicSyncTests {
    private static let classicID = "000A27001A2B3C4D"
    private let signer = Hash58(fireWireID: FireWireID(hexString: classicID)!)
    private let unsigned = ITunesDBFixtureBuilder(playlists: [
        FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [])
    ], includesAlbumSection: true).build()

    private func device(productID: Int, serial: String? = classicID, volume: URL = URL(filePath: "/Volumes/iPod"))
        -> IPodDevice {
        IPodDevice(id: "1", volumeURL: volume, volumeName: "iPod", capacityBytes: nil, availableBytes: nil,
                   sysInfo: .empty, usbIdentity: IPodUSBIdentity(vendorString: "Apple", productString: "iPod",
                                                                  serialNumber: serial, vendorID: 0x05AC,
                                                                  productID: productID))
    }

    private func coveredSong(in volume: TemporaryIPodVolume) async throws -> IPodSyncRequest {
        let silence = try AudioFixtureWriter.writeSilence(to: volume.url.appending(path: "source/plain.m4a"))
        let source = volume.url.appending(path: "source/song.m4a")
        let cover = TestImage.make(width: 500, height: 500, top: TestImage.color(1, 0, 0))
        try await AudioFixtureWriter.embedCoverArt(TestImage.pngData(cover), from: silence, to: source)
        return IPodSyncRequest(sourceURL: source, draft: ITunesTrackDraft(title: "Song", album: "Album",
                                                                          fileSize: try Data(contentsOf: source).count))
    }

    @Test func videoIPodsSyncUnsignedWithTwoCoverSizes() throws {
        let syncer = try IPodTrackSyncer(device: device(productID: 0x1209))
        #expect(syncer.signer == nil)
        #expect(syncer.formats == ArtworkFormat.videoIPod)
    }

    @Test func classicsSignWithTheirFireWireID() throws {
        let syncer = try IPodTrackSyncer(device: device(productID: 0x1261))
        #expect(syncer.formats == ArtworkFormat.classicIPod)
        #expect(try syncer.signer?.sign(unsigned) == signer.sign(unsigned))
    }

    @Test func classicsWithoutAFireWireIDAreRefused() {
        #expect(throws: IPodSyncError.missingFireWireID) {
            try IPodTrackSyncer(device: device(productID: 0x1261, serial: nil))
        }
    }

    @Test func unidentifiedIPodsAreRefused() {
        #expect(throws: IPodSyncError.self) { try IPodTrackSyncer(device: device(productID: 0x1234)) }
    }

    @Test func classicSyncWritesASignedDatabaseAndFourCoverSizes() async throws {
        let volume = try TemporaryIPodVolume(database: try signer.sign(unsigned))
        let syncer = try IPodTrackSyncer(device: device(productID: 0x1261, volume: volume.url))
        _ = try await syncer.sync(adding: [try await coveredSong(in: volume)])

        let written = try Data(contentsOf: volume.databaseURL)
        #expect(signer.isValid(written))
        #expect(try ITunesDBParser(data: written).parse().tracks.map(\.title) == ["Song"])
        for format in ArtworkFormat.classicIPod {
            let ithmb = volume.url.appending(path: "iPod_Control/Artwork/\(format.fileName)")
            #expect(try Data(contentsOf: ithmb).count == format.byteCount)
        }
    }

    @Test func signsADatabaseThatWasNeverSigned() async throws {
        let volume = try TemporaryIPodVolume(database: unsigned)
        let syncer = try IPodTrackSyncer(device: device(productID: 0x1261, volume: volume.url))
        _ = try await syncer.sync(adding: [try await coveredSong(in: volume)])
        #expect(signer.isValid(try Data(contentsOf: volume.databaseURL)))
    }

    @Test func refusesADatabaseSignedForAnotherDevice() async throws {
        let foreign = try Hash58(fireWireID: #require(FireWireID(hexString: "0123456789ABCDEF"))).sign(unsigned)
        let volume = try TemporaryIPodVolume(database: foreign)
        let syncer = try IPodTrackSyncer(device: device(productID: 0x1261, volume: volume.url))
        let request = try await coveredSong(in: volume)
        await #expect(throws: IPodSyncError.signatureMismatch) {
            try await syncer.sync(adding: [request])
        }
        #expect(try Data(contentsOf: volume.databaseURL) == foreign)
    }
}
