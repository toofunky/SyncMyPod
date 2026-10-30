import Foundation
import SwiftData
import Testing
@testable import SyncMyPod

@MainActor
struct PlayerSyncTabModelTests {
    private let container = ModelContainer.makeInMemory()
    private let config = AudioPlayerConfig(name: "Player", rootPath: "", musicFolder: "Music",
                                           playlistFolder: "Playlists")

    @Test func readsThePlayerAndCreatesSettings() async throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let device = try volume.device
        let model = PlayerSyncTabModel()
        await model.reload(SyncLibrarySources(), from: device, context: container.mainContext)
        #expect(model.settings?.deviceID == device.id)
        #expect(model.contents != nil)
        #expect(model.missingSources.isEmpty)
        #expect(model.freeBytes != nil)
    }

    @Test func aRemovedDownloadIsListedAsMissing() async throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let folder = volume.root.appending(path: "Downloads", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let episode = folder.appending(path: "Episode.mp3")
        try Data(repeating: 1, count: 512).write(to: episode)
        let request = SyncRequest(sourceURL: episode, tags: TrackTags(title: "Episode", fileSize: 512),
                                  source: SyncSource(fileSize: 512, modificationDate: .now, artworkFingerprint: nil),
                                  kind: .podcast)
        let contents = await PlayerDeviceContents.load(from: try volume.device)
        _ = try await PlayerTrackSyncer(device: volume.device)
            .sync(contents.planner(for: config).plan(selected: [request], playlists: nil))
        try FileManager.default.removeItem(at: episode)

        let model = PlayerSyncTabModel()
        let sources = SyncLibrarySources(podcastFolderPath: folder.path(percentEncoded: false))
        await model.reload(sources, from: try volume.device, context: container.mainContext)
        #expect(model.missingSources == [request.sourcePath])
    }
}
