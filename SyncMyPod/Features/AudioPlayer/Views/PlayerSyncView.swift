import SwiftData
import SwiftUI

struct PlayerSyncView: View {
    let device: AudioPlayerDevice

    @Environment(\.modelContext) private var context
    @Environment(DeviceSyncModel.self) private var syncModel
    @Environment(MediaFolders.self) private var mediaFolders: MediaFolders?
    @Query private var tracks: [LibraryTrack]
    @Query private var folders: [LibraryFolder]
    @Query(sort: \LibraryPlaylist.createdAt) private var playlists: [LibraryPlaylist]
    @Query private var podcasts: [Podcast]
    @Query private var audiobooks: [Audiobook]
    @State private var settings: DeviceSyncSettings?
    @State private var contents: PlayerDeviceContents?
    @State private var missingSources: Set<String> = []
    @State private var sidecars = LibrarySidecars()
    @State private var freeBytes: Int64?

    /// Reloads after a sync, and when covers or lyrics are turned on so the library is looked through for them.
    private var reloadID: String {
        "\(device.id)#\(syncModel.completedSyncCount)#\(device.config.copyCovers)#\(device.config.copyLyricFiles)"
    }

    var body: some View {
        content
            .task(id: reloadID) { await reload() }
            .syncProgressSheet()
    }

    @ViewBuilder
    private var content: some View {
        if tracks.isEmpty && downloadedPaths.isEmpty && audiobooks.isEmpty {
            ContentUnavailableView("No Music to Sync", systemImage: "music.note.house",
                                   description: Text("Choose a music folder in Music Library, download podcast "
                                                     + "episodes or choose an audiobook folder first."))
        } else if let settings, let contents {
            PlayerSyncForm(settings: settings,
                           library: SyncLibrarySnapshot(tracks: tracks, playlists: playlists, podcasts: podcasts,
                                                        audiobooks: audiobooks,
                                                        preservingAlbumArtist: device.config.preserveAlbumArtist),
                           contents: contents, config: device.config, missingSources: missingSources,
                           sidecars: sidecars, freeBytes: freeBytes ?? device.availableBytes,
                           isSyncing: syncModel.isSyncing) {
                syncModel.sync($0, to: device)
            }
        } else {
            ProgressView("Reading player…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var downloadedPaths: Set<String> {
        Set(podcasts.flatMap(\.episodes).compactMap(\.downloadedFilePath))
    }

    /// Copies whose library file, download or audiobook file is gone for good are removed; ones on an unplugged
    /// drive are kept.
    private func reload() async {
        settings = DeviceSyncSettings.settings(for: device.id, in: context)
        let loaded = await PlayerDeviceContents.load(from: device)
        let libraryPaths = tracks.map(\.filePath)
        let synced = loaded.manifest.entries.keys
        let missingSongs = folders.first.map {
            MissingSourceFinder(folderPath: $0.path).missing(synced, notIn: Set(libraryPaths))
        } ?? []
        let bookFiles = Set(audiobooks.flatMap(\.files).map(\.filePath))
        let removedEpisodes = RemovedSourceFinder(folderPath: mediaFolders?.podcasts.path)
            .missing(synced, known: downloadedPaths)
        let removedBookFiles = RemovedSourceFinder(folderPath: mediaFolders?.audiobooks.path)
            .missing(synced, known: bookFiles)
        missingSources = missingSongs.union(removedEpisodes).union(removedBookFiles)
        sidecars = await LibrarySidecarFinder.find(besideSongsAt: libraryPaths + bookFiles.sorted(),
                                                   covers: device.config.copyCovers,
                                                   lyrics: device.config.copyLyricFiles)
        contents = loaded
        let values = try? device.volumeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        freeBytes = values?.volumeAvailableCapacity.map(Int64.init)
    }
}

#if DEBUG
#Preview {
    PlayerSyncView(device: .preview)
        .environment(DeviceSyncModel())
        .modelContainer(.preview)
}
#endif
