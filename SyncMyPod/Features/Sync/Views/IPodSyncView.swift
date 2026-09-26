import SwiftData
import SwiftUI

struct IPodSyncView: View {
    let device: IPodDevice

    @Environment(\.modelContext) private var context
    @Environment(\.iTunesDBLoader) private var loader
    @Environment(IPodSyncModel.self) private var syncModel
    @Query private var tracks: [LibraryTrack]
    @Query private var folders: [LibraryFolder]
    @Query(sort: \LibraryPlaylist.createdAt) private var playlists: [LibraryPlaylist]
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
        if tracks.isEmpty {
            ContentUnavailableView("No Music to Sync", systemImage: "music.note.house",
                                   description: Text("Choose a music folder in Music Library first."))
        } else if let loadError {
            ContentUnavailableView("Couldn't Read iPod", systemImage: "exclamationmark.triangle",
                                   description: Text(loadError))
        } else if let settings, let onDevice {
            SyncSettingsForm(settings: settings, tracks: tracks, playlists: playlists, onDevice: onDevice,
                             manifest: manifest, freeBytes: freeBytes ?? device.availableBytes,
                             isSyncing: syncModel.isSyncing) {
                syncModel.sync($0.syncRequests, removing: $0.removalIDs, playlists: $0.playlists, to: device)
            }
        } else {
            ProgressView("Reading iPod…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func reload() async {
        let settings = IPodSyncSettings.settings(for: device.id, in: context)
        self.settings = settings
        let requests = tracks.map { $0.syncRequest(preservingAlbumArtist: settings.preservesAlbumArtist) }
        do {
            let database = try await loader.load(device.volumeURL)
            manifest = await IPodControlFiles(volumeURL: device.volumeURL)
                .manifest(adopting: requests, onDevice: database.tracks,
                          libraryFolder: folders.first?.path)
            onDevice = database
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        let values = try? device.volumeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        freeBytes = values?.volumeAvailableCapacity.map(Int64.init)
    }
}

#if DEBUG
#Preview {
    IPodSyncView(device: .preview)
        .environment(\.iTunesDBLoader, .preview)
        .environment(IPodSyncModel())
        .modelContainer(.preview)
}
#endif
