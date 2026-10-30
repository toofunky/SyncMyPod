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
    @State private var model = PlayerSyncTabModel()

    /// Reloads after a sync, and when covers or lyrics are turned on so the library is looked through for them.
    private var reloadID: String {
        "\(device.id)#\(syncModel.completedSyncCount)#\(device.config.copyCovers)#\(device.config.copyLyricFiles)"
    }

    var body: some View {
        content
            .task(id: reloadID) { await model.reload(sources, from: device, context: context) }
            .syncProgressSheet()
    }

    @ViewBuilder
    private var content: some View {
        if sources.isEmpty {
            ContentUnavailableView("No Music to Sync", systemImage: "music.note.house",
                                   description: Text("Choose a music folder in Music Library, download podcast "
                                                     + "episodes or choose an audiobook folder first."))
        } else if let settings = model.settings, let contents = model.contents {
            PlayerSyncForm(settings: settings, library: model.library(from: sources, for: device),
                           contents: contents, config: device.config, missingSources: model.missingSources,
                           sidecars: model.sidecars, freeBytes: model.freeBytes ?? device.availableBytes,
                           isSyncing: syncModel.isSyncing) {
                syncModel.sync($0, to: device)
            }
        } else {
            ProgressView("Reading player…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var sources: SyncLibrarySources {
        SyncLibrarySources(tracks: tracks, playlists: playlists, podcasts: podcasts, audiobooks: audiobooks,
                           musicFolderPath: folders.first?.path, podcastFolderPath: mediaFolders?.podcasts.path,
                           audiobookFolderPath: mediaFolders?.audiobooks.path)
    }
}

#if DEBUG
#Preview {
    PlayerSyncView(device: .preview)
        .environment(DeviceSyncModel())
        .modelContainer(.preview)
}
#endif
