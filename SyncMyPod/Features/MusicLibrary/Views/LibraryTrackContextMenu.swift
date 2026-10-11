import AppKit
import SwiftData
import SwiftUI

/// The right-click menu for library songs, given in the order shown.
struct LibraryTrackContextMenu: View {
    let tracks: [LibraryTrack]
    let devices: [ConnectedDevice]
    var addToDevice: ((ConnectedDevice, [LibraryTrack]) -> Void)?
    let playlists: [LibraryPlaylist]
    let actions: SongMenuActions

    var body: some View {
        AddToDeviceMenu(devices: devices) { addToDevice?($0, tracks) }
            .disabled(addToDevice == nil || tracks.isEmpty)
        AddToPlaylistMenu(playlists: playlists.filter { !$0.isFavorites }, onAdd: addToPlaylist)
            .disabled(tracks.isEmpty)
        SongMenuItems(tracks: tracks, favorites: playlists.first(where: \.isFavorites), actions: actions)
        Divider()
        ShowInPlaylistMenu(playlists: playlistsContainingTracks) { actions.showPlaylist?($0) }
            .disabled(actions.showPlaylist == nil || tracks.isEmpty)
        Button("Show in Finder", systemImage: "folder", action: showInFinder)
            .disabled(tracks.isEmpty)
    }

    private var playlistsContainingTracks: [LibraryPlaylist] {
        let paths = Set(tracks.map(\.filePath))
        return playlists.filter { !paths.isDisjoint(with: $0.trackPaths) }
    }

    /// `nil` asks for a name for a new playlist of the songs.
    private func addToPlaylist(_ playlist: LibraryPlaylist?) {
        if let playlist {
            playlist.append(tracks)
        } else {
            actions.newPlaylist(tracks)
        }
    }

    private func showInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting(tracks.map { URL(filePath: $0.filePath) })
    }
}

#if DEBUG
#Preview {
    Menu("Song") {
        LibraryTrackContextMenu(tracks: [LibraryTrack.previewTracks[0]], devices: [.iPod(.preview)],
                                addToDevice: { _, _ in }, playlists: [.preview], actions: SongMenuActions())
    }
    .padding()
    .modelContainer(.emptyPreview)
}
#endif
