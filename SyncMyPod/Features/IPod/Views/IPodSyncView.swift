import SwiftData
import SwiftUI

struct IPodSyncView: View {
    let device: IPodDevice

    @Environment(\.modelContext) private var context
    @Environment(\.iTunesDBLoader) private var loader
    @Environment(DeviceSyncModel.self) private var syncModel
    @Environment(PodcastDownloads.self) private var podcastDownloads: PodcastDownloads?
    @Environment(MediaFolders.self) private var mediaFolders: MediaFolders?
    @Query private var tracks: [LibraryTrack]
    @Query private var folders: [LibraryFolder]
    @Query(sort: \LibraryPlaylist.createdAt) private var playlists: [LibraryPlaylist]
    @Query private var podcasts: [Podcast]
    @Query private var audiobooks: [Audiobook]
    @State private var model = IPodSyncTabModel()
    @State private var isManagingStorage = false

    var body: some View {
        content
            .task(id: "\(device.id)#\(syncModel.completedSyncCount)") { await reload() }
            .sheet(isPresented: $isManagingStorage) { ManageStorageSheet(device: device) }
            .syncProgressSheet(isEnabled: !isManagingStorage)
    }

    @ViewBuilder
    private var content: some View {
        if sources.isEmpty {
            ContentUnavailableView("No Music to Sync", systemImage: "music.note.house",
                                   description: Text("Choose a music folder in Music Library, download podcast "
                                                     + "episodes or choose an audiobook folder first."))
        } else if let loadError = model.loadError {
            ContentUnavailableView("Couldn't Read iPod", systemImage: "exclamationmark.triangle",
                                   description: Text(loadError))
        } else if let settings = model.settings, let onDevice = model.onDevice {
            SyncSettingsForm(settings: settings, library: model.library(from: sources, for: device, settings: settings),
                             onDevice: onDevice, manifest: model.manifest,
                             freeBytes: model.freeBytes ?? device.availableBytes, isSyncing: syncModel.isSyncing) {
                syncModel.sync($0.syncRequests, removing: $0.removalIDs, playlists: $0.playlists, to: device)
            } onManageStorage: {
                isManagingStorage = true
            }
        } else {
            ProgressView("Reading iPod…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var sources: SyncLibrarySources {
        SyncLibrarySources(tracks: tracks, playlists: playlists, podcasts: podcasts, audiobooks: audiobooks,
                           musicFolderPath: folders.first?.path, podcastFolderPath: mediaFolders?.podcasts.path,
                           audiobookFolderPath: mediaFolders?.audiobooks.path)
    }

    /// Episodes downloaded before their file details were read get them first, so they're listed correctly.
    private func reload() async {
        await podcastDownloads?.readMissingAudioDetails(of: podcasts, context: context)
        await model.reload(sources, from: device, loader: loader, context: context)
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
