import Foundation
import Observation
import SwiftData

/// What the iPod's Sync tab shows: its settings, the iPod's database and manifest, and its free space.
@Observable
@MainActor
final class IPodSyncTabModel {
    private(set) var settings: DeviceSyncSettings?
    private(set) var onDevice: ITunesDatabase?
    private(set) var manifest = LoadedSyncManifest()
    private(set) var freeBytes: Int64?
    private(set) var loadError: String?

    func library(from sources: SyncLibrarySources, for device: IPodDevice,
                 settings: DeviceSyncSettings) -> SyncLibrarySnapshot {
        SyncLibrarySnapshot(tracks: sources.tracks.filter(\.codec.syncsToIPod), playlists: sources.playlists,
                            podcasts: sources.podcasts, audiobooks: sources.audiobooks, forIPod: true,
                            preservingAlbumArtist: settings.preservesAlbumArtist,
                            embeddingLyricsSidecars: settings.syncsLyricsSidecars && device.showsLyrics)
    }

    /// Reads the iPod and matches what's on it to the library.
    func reload(_ sources: SyncLibrarySources, from device: IPodDevice, loader: ITunesDBLoader,
                context: ModelContext) async {
        await sources.readMissingEpisodeDetails(context: context)
        let settings = DeviceSyncSettings.settings(for: device.id, in: context)
        self.settings = settings
        let library = library(from: sources, for: device, settings: settings)
        let requests = library.tracks.map(\.request) + library.podcasts.flatMap(\.episodes)
            + library.audiobooks.flatMap(\.files)
        do {
            let database = try await loader.load(device.volumeURL)
            let loaded = await IPodControlFiles(volumeURL: device.volumeURL)
                .manifest(adopting: requests, onDevice: database.tracks, libraryFolder: sources.musicFolderPath)
            manifest = withRemovedDownloads(loaded, sources: sources)
            importPositions(from: database, on: device, manifest: loaded.manifest, sources: sources, context: context)
            onDevice = database
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        freeBytes = device.volumeURL.volumeAvailableBytes
    }

    /// Positions saved on the iPod since its last sync are still in its Play Counts file, so they're read too.
    private func importPositions(from database: ITunesDatabase, on device: IPodDevice, manifest: SyncManifest,
                                 sources: SyncLibrarySources, context: ModelContext) {
        let playCounts = IPodControlFiles(volumeURL: device.volumeURL).playCounts()
        let tracks = IPodPositionImporter.withPendingBookmarks(database.tracks, playCounts: playCounts)
        IPodPositionImporter(deviceID: device.id, context: context)
            .importPositions(from: tracks, manifest: manifest, podcasts: sources.podcasts,
                             audiobooks: sources.audiobooks)
    }

    /// Episodes whose download was removed, and books gone from the audiobook folder, come off the iPod too, as
    /// their copies do on a player.
    private func withRemovedDownloads(_ loaded: LoadedSyncManifest, sources: SyncLibrarySources) -> LoadedSyncManifest {
        let entries = loaded.manifest.entries
        var updated = loaded
        updated.strayDatabaseIDs.formUnion(sources.removedDownloads(among: entries.keys).compactMap {
            entries[$0]?.databaseID
        })
        return updated
    }
}
