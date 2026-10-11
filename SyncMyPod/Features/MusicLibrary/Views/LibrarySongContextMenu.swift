import SwiftData
import SwiftUI

/// The full song menu for album song lists, wiring up the device actions the Songs table gets from its parent.
struct LibrarySongContextMenu: View {
    let tracks: [LibraryTrack]
    let playlists: [LibraryPlaylist]
    let actions: SongMenuActions

    @Environment(\.modelContext) private var context
    @Environment(DeviceMountWatcher.self) private var watcher
    @Environment(DeviceSyncModel.self) private var syncModel

    var body: some View {
        LibraryTrackContextMenu(tracks: tracks, devices: devices, addToDevice: addToDevice,
                                playlists: playlists, actions: actions)
    }

    private var devices: [ConnectedDevice] {
        syncModel.isSyncing ? [] : watcher.connectedDevices
    }

    private var addToDevice: ((ConnectedDevice, [LibraryTrack]) -> Void)? {
        guard !devices.isEmpty else { return nil }
        return { device, tracks in syncModel.add(tracks, to: device, in: context) }
    }
}

#if DEBUG
#Preview {
    Menu("Song") {
        LibrarySongContextMenu(tracks: [LibraryTrack.previewTracks[0]], playlists: [.preview],
                               actions: SongMenuActions(editTags: { _ in }, showPlaylist: { _ in }))
    }
    .padding()
    .environment(DeviceMountWatcher.preview(connectedDevices: [.iPod(.preview)]))
    .environment(DeviceSyncModel())
    .modelContainer(.emptyPreview)
}
#endif
