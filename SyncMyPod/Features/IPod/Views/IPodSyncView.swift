import SwiftData
import SwiftUI

struct IPodSyncView: View {
    let device: IPodDevice

    @Environment(\.modelContext) private var context
    @Environment(\.iTunesDBLoader) private var loader
    @Environment(DeviceSyncModel.self) private var syncModel
    @Environment(PodcastDownloads.self) private var podcastDownloads: PodcastDownloads?
    @Environment(PodcastFolder.self) private var podcastFolder: PodcastFolder?
    @Environment(AudiobookFolder.self) private var audiobookFolder: AudiobookFolder?
    @Query private var tracks: [LibraryTrack]
    @Query private var folders: [LibraryFolder]
    @Query(sort: \LibraryPlaylist.createdAt) private var playlists: [LibraryPlaylist]
    @Query private var podcasts: [Podcast]
    @Query private var audiobooks: [Audiobook]
    @State private var settings: DeviceSyncSettings?
    @State private var onDevice: ITunesDatabase?
    @State private var manifest = LoadedSyncManifest()
    @State private var freeBytes: Int64?
    @State private var loadError: String?
    @State private var isManagingStorage = false

    var body: some View {
        content
            .task(id: "\(device.id)#\(syncModel.completedSyncCount)") { await reload() }
            .sheet(isPresented: $isManagingStorage) { ManageStorageSheet(device: device) }
            .syncProgressSheet(isEnabled: !isManagingStorage)
    }

    @ViewBuilder
    private var content: some View {
        if tracks.isEmpty && !hasDownloads && audiobooks.isEmpty {
            ContentUnavailableView("No Music to Sync", systemImage: "music.note.house",
                                   description: Text("Choose a music folder in Music Library, download podcast "
                                                     + "episodes or choose an audiobook folder first."))
        } else if let loadError {
            ContentUnavailableView("Couldn't Read iPod", systemImage: "exclamationmark.triangle",
                                   description: Text(loadError))
        } else if let settings, let onDevice {
            SyncSettingsForm(settings: settings, library: library(settings), onDevice: onDevice,
                             manifest: manifest, freeBytes: freeBytes ?? device.availableBytes,
                             isSyncing: syncModel.isSyncing) {
                syncModel.sync($0.syncRequests, removing: $0.removalIDs, playlists: $0.playlists, to: .iPod(device))
            } onManageStorage: {
                isManagingStorage = true
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

    private func library(_ settings: DeviceSyncSettings) -> SyncLibrarySnapshot {
        SyncLibrarySnapshot(tracks: iPodTracks, playlists: playlists, podcasts: podcasts, audiobooks: audiobooks,
                            forIPod: true, preservingAlbumArtist: settings.preservesAlbumArtist,
                            embeddingLyricsSidecars: embedsLyricsSidecars(settings))
    }

    private func embedsLyricsSidecars(_ settings: DeviceSyncSettings) -> Bool {
        settings.syncsLyricsSidecars && device.showsLyrics
    }

    private func reload() async {
        let settings = DeviceSyncSettings.settings(for: device.id, in: context)
        self.settings = settings
        await podcastDownloads?.readMissingAudioDetails(of: podcasts, context: context)
        let library = library(settings)
        let requests = library.tracks.map(\.request) + library.podcasts.flatMap(\.episodes)
            + library.audiobooks.flatMap(\.files)
        do {
            let database = try await loader.load(device.volumeURL)
            let loaded = await IPodControlFiles(volumeURL: device.volumeURL)
                .manifest(adopting: requests, onDevice: database.tracks, libraryFolder: folders.first?.path)
            manifest = withRemovedDownloads(loaded)
            importPositions(from: database, manifest: loaded.manifest)
            onDevice = database
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        let values = try? device.volumeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        freeBytes = values?.volumeAvailableCapacity.map(Int64.init)
    }

    /// Positions saved on the iPod since its last sync are still in its Play Counts file, so they're read too.
    private func importPositions(from database: ITunesDatabase, manifest: SyncManifest) {
        let playCounts = IPodControlFiles(volumeURL: device.volumeURL).playCounts()
        let tracks = IPodPositionImporter.withPendingBookmarks(database.tracks, playCounts: playCounts)
        IPodPositionImporter(deviceID: device.id, context: context)
            .importPositions(from: tracks, manifest: manifest, podcasts: podcasts, audiobooks: audiobooks)
    }

    /// Episodes whose download was removed, and books gone from the audiobook folder, come off the iPod too, as
    /// their copies do on a player.
    private func withRemovedDownloads(_ loaded: LoadedSyncManifest) -> LoadedSyncManifest {
        let downloaded = Set(podcasts.flatMap(\.episodes).compactMap(\.downloadedFilePath))
        let bookFiles = Set(audiobooks.flatMap(\.files).map(\.filePath))
        let entries = loaded.manifest.entries
        let removed = RemovedSourceFinder(folderPath: podcastFolder?.path)
            .missing(entries.keys, known: downloaded)
            .union(RemovedSourceFinder(folderPath: audiobookFolder?.path)
                .missing(entries.keys, known: bookFiles))
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
