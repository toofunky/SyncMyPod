import Foundation
import SwiftData
import Testing
@testable import SyncMyPod

@MainActor
struct IPodSyncTabModelTests {
    private let container = ModelContainer.makeInMemory()
    private let database = ITunesDBFixtureBuilder(playlists: [
        FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [])
    ], includesAlbumSection: true).build()

    private func device(on volume: TemporaryIPodVolume) -> IPodDevice {
        IPodDevice(id: "ipod", volumeURL: volume.url, volumeName: "iPod", capacityBytes: nil, availableBytes: nil,
                   sysInfo: .empty, usbIdentity: nil)
    }

    @Test func readsTheDatabaseAndCreatesSettings() async throws {
        let volume = try TemporaryIPodVolume(database: database)
        let model = IPodSyncTabModel()
        await model.reload(SyncLibrarySources(), from: device(on: volume), loader: .live,
                           context: container.mainContext)
        #expect(model.loadError == nil)
        #expect(model.onDevice != nil)
        #expect(model.settings?.deviceID == "ipod")
        #expect(model.freeBytes != nil)
    }

    @Test func reportsADatabaseThatCannotBeRead() async throws {
        let volume = try TemporaryIPodVolume(database: nil)
        let model = IPodSyncTabModel()
        await model.reload(SyncLibrarySources(), from: device(on: volume), loader: .live,
                           context: container.mainContext)
        #expect(model.loadError != nil)
        #expect(model.onDevice == nil)
    }

    @Test func aRemovedDownloadIsMarkedForRemovalFromTheIPod() async throws {
        let volume = try TemporaryIPodVolume(database: database)
        let episode = try volume.makeSourceFile(named: "Downloads/Episode.mp3")
        let request = SyncRequest(sourceURL: episode, tags: TrackTags(title: "Episode", fileSize: 1_024),
                                  source: SyncSource(fileSize: 1_024, modificationDate: .now, artworkFingerprint: nil),
                                  kind: .podcast)
        let outcome = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: [request])
        try FileManager.default.removeItem(at: episode)

        let model = IPodSyncTabModel()
        let folder = volume.url.appending(path: "Downloads").path(percentEncoded: false)
        await model.reload(SyncLibrarySources(podcastFolderPath: folder), from: device(on: volume), loader: .live,
                           context: container.mainContext)
        #expect(Set(outcome.addedDatabaseIDs.values).isSubset(of: model.manifest.strayDatabaseIDs))
        #expect(!outcome.addedDatabaseIDs.isEmpty)
    }
}
