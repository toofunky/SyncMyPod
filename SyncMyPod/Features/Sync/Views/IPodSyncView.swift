import SwiftData
import SwiftUI

struct IPodSyncView: View {
    let device: IPodDevice

    @Environment(\.modelContext) private var context
    @Environment(\.iTunesDBLoader) private var loader
    @Environment(DeviceSyncModel.self) private var syncModel
    @Environment(PodcastDownloads.self) private var podcastDownloads: PodcastDownloads?
    @Environment(PodcastFolder.self) private var podcastFolder: PodcastFolder?
    @Query private var tracks: [LibraryTrack]
    @Query private var folders: [LibraryFolder]
    @Query(sort: \LibraryPlaylist.createdAt) private var playlists: [LibraryPlaylist]
    @Query private var podcasts: [Podcast]
    @State private var settings: IPodSyncSettings?
    @State private var onDevice: ITunesDatabase?
    @State private var manifest = LoadedSyncManifest()
    @State private var freeBytes: Int64?
    @State private var loadError: String?

    var body: some View {
        content
            .task(id: "\(device.id)#\(syncModel.completedSyncCount)") { await reload() }
            .syncProgressSheet()
    }

    @ViewBuilder
    private var content: some View {
        if tracks.isEmpty && !hasDownloads {
            ContentUnavailableView("No Music to Sync", systemImage: "music.note.house",
                                   description: Text("Choose a music folder in Music Library, or download podcast "
                                                     + "episodes, first."))
        } else if let loadError {
            ContentUnavailableView("Couldn't Read iPod", systemImage: "exclamationmark.triangle",
                                   description: Text(loadError))
        } else if let settings, let onDevice {
            SyncSettingsForm(settings: settings, library: library(settings), onDevice: onDevice,
                             manifest: manifest, freeBytes: freeBytes ?? device.availableBytes,
                             isSyncing: syncModel.isSyncing) {
                syncModel.sync($0.syncRequests, removing: $0.removalIDs, playlists: $0.playlists, to: .iPod(device))
            }
        } else {
            ProgressView("Reading iPod…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var iPodTracks: [LibraryTrack] {
        tracks.filter(\.codec.syncsToIPod)
    }

    private var hasDownloads: Bool { podcasts.contains { $0.episodes.contains(where: \.isDownloaded) } }

    private func library(_ settings: IPodSyncSettings) -> SyncLibrarySnapshot {
        SyncLibrarySnapshot(tracks: iPodTracks, playlists: playlists, podcasts: podcasts, podcastsForIPod: true,
                            preservingAlbumArtist: settings.preservesAlbumArtist,
                            embeddingLyricsSidecars: embedsLyricsSidecars(settings))
    }

    private func embedsLyricsSidecars(_ settings: IPodSyncSettings) -> Bool {
        settings.syncsLyricsSidecars && device.showsLyrics
    }

    private func reload() async {
        let settings = IPodSyncSettings.settings(for: device.id, in: context)
        self.settings = settings
        await podcastDownloads?.readMissingAudioDetails(of: podcasts, context: context)
        let library = library(settings)
        let requests = library.tracks.map(\.request) + library.podcasts.flatMap(\.episodes)
        do {
            let database = try await loader.load(device.volumeURL)
            let loaded = await IPodControlFiles(volumeURL: device.volumeURL)
                .manifest(adopting: requests, onDevice: database.tracks, libraryFolder: folders.first?.path)
            manifest = withRemovedDownloads(loaded)
            onDevice = database
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        let values = try? device.volumeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        freeBytes = values?.volumeAvailableCapacity.map(Int64.init)
    }

    /// Episodes whose download was removed come off the iPod too, as their copies do on a player.
    private func withRemovedDownloads(_ loaded: LoadedSyncManifest) -> LoadedSyncManifest {
        let downloaded = Set(podcasts.flatMap(\.episodes).compactMap(\.downloadedFilePath))
        let entries = loaded.manifest.entries
        let removed = PodcastMissingSourceFinder(folderPath: podcastFolder?.path)
            .missing(entries.keys, downloaded: downloaded)
        var updated = loaded
        updated.strayDatabaseIDs.formUnion(removed.compactMap { entries[$0]?.databaseID })
        return updated
    }
}

#if DEBUG
#Preview {
    IPodSyncView(device: .preview)
        .environment(\.iTunesDBLoader, .preview)
        .environment(DeviceSyncModel())
        .modelContainer(.preview)
}
#endif
