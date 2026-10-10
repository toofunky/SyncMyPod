import SwiftData
import SwiftUI

/// The full song menu for album song lists, wiring up the device and playlist actions the Songs table gets from its parent.
struct LibrarySongContextMenu: View {
    let tracks: [LibraryTrack]
    let playlists: [LibraryPlaylist]
    let editLyrics: (LibraryTrack) -> Void
    let removeLyrics: (LibraryTrack) -> Void
    var showPlaylist: ((LibraryPlaylist) -> Void)?

    @Environment(\.modelContext) private var context
    @Environment(DeviceMountWatcher.self) private var watcher
    @Environment(DeviceSyncModel.self) private var syncModel

    var body: some View {
        LibraryTrackContextMenu(tracks: tracks, devices: devices, addToDevice: addToDevice,
                                playlists: playlists, addToPlaylist: add,
                                editLyrics: editLyrics, removeLyrics: removeLyrics, showPlaylist: showPlaylist)
    }

    private var devices: [ConnectedDevice] {
        syncModel.isSyncing ? [] : watcher.connectedDevices
    }

    private var addToDevice: ((ConnectedDevice, [LibraryTrack]) -> Void)? {
        guard !devices.isEmpty else { return nil }
        return { device, tracks in syncModel.add(tracks, to: device, in: context) }
    }

    /// `nil` makes a new playlist of the songs.
    private func add(to playlist: LibraryPlaylist?) {
        if let playlist {
            playlist.append(tracks)
        } else {
            context.insert(LibraryPlaylist(trackPaths: tracks.map(\.filePath)))
        }
    }
}

#if DEBUG
#Preview {
    Menu("Song") {
        LibrarySongContextMenu(tracks: [LibraryTrack.previewTracks[0]], playlists: [.preview],
                               editLyrics: { _ in }, removeLyrics: { _ in }, showPlaylist: { _ in })
    }
    .padding()
    .environment(DeviceMountWatcher.preview(connectedDevices: [.iPod(.preview)]))
    .environment(DeviceSyncModel())
    .modelContainer(.emptyPreview)
}
#endif
