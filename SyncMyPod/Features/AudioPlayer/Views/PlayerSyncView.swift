import SwiftData
import SwiftUI

struct PlayerSyncView: View {
    let device: AudioPlayerDevice

    @Environment(\.modelContext) private var context
    @Environment(DeviceSyncModel.self) private var syncModel
    @Query private var tracks: [LibraryTrack]
    @Query private var folders: [LibraryFolder]
    @Query(sort: \LibraryPlaylist.createdAt) private var playlists: [LibraryPlaylist]
    @State private var settings: IPodSyncSettings?
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
        if tracks.isEmpty {
            ContentUnavailableView("No Music to Sync", systemImage: "music.note.house",
                                   description: Text("Choose a music folder in Music Library first."))
        } else if let settings, let contents {
            PlayerSyncForm(settings: settings,
                           library: SyncLibrarySnapshot(tracks: tracks, playlists: playlists,
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

    /// Copies whose library file is gone for good are removed; ones on an unplugged music drive are kept.
    private func reload() async {
        settings = IPodSyncSettings.settings(for: device.id, in: context)
        let loaded = await PlayerDeviceContents.load(from: device)
        let libraryPaths = tracks.map(\.filePath)
        missingSources = folders.first.map {
            MissingSourceFinder(folderPath: $0.path).missing(loaded.manifest.entries.keys, notIn: Set(libraryPaths))
        } ?? []
        sidecars = await LibrarySidecarFinder.find(besideSongsAt: libraryPaths, covers: device.config.copyCovers,
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
