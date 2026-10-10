import AppKit
import SwiftData
import SwiftUI

/// The right-click menu for library songs, given in the order shown.
struct LibraryTrackContextMenu: View {
    let tracks: [LibraryTrack]
    let devices: [ConnectedDevice]
    var addToDevice: ((ConnectedDevice, [LibraryTrack]) -> Void)?
    let playlists: [LibraryPlaylist]
    /// `nil` makes a new playlist of the songs.
    let addToPlaylist: (LibraryPlaylist?) -> Void
    let editLyrics: (LibraryTrack) -> Void
    let removeLyrics: (LibraryTrack) -> Void
    var showPlaylist: ((LibraryPlaylist) -> Void)?

    var body: some View {
        AddToDeviceMenu(devices: devices) { addToDevice?($0, tracks) }
            .disabled(addToDevice == nil || tracks.isEmpty)
        AddToPlaylistMenu(playlists: playlists.filter { !$0.isFavorites }, onAdd: addToPlaylist)
            .disabled(tracks.isEmpty)
        SongMenuItems(tracks: tracks, favorites: playlists.first(where: \.isFavorites),
                      editLyrics: editLyrics, removeLyrics: removeLyrics)
        Divider()
        ShowInPlaylistMenu(playlists: playlistsContainingTracks) { showPlaylist?($0) }
            .disabled(showPlaylist == nil || tracks.isEmpty)
        Button("Show in Finder", systemImage: "folder", action: showInFinder)
            .disabled(tracks.isEmpty)
    }

    private var playlistsContainingTracks: [LibraryPlaylist] {
        let paths = Set(tracks.map(\.filePath))
        return playlists.filter { !paths.isDisjoint(with: $0.trackPaths) }
    }

    private func showInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting(tracks.map { URL(filePath: $0.filePath) })
    }
}

#if DEBUG
#Preview {
    Menu("Song") {
        LibraryTrackContextMenu(tracks: [LibraryTrack.previewTracks[0]], devices: [.iPod(.preview)],
                                addToDevice: { _, _ in }, playlists: [.preview], addToPlaylist: { _ in },
                                editLyrics: { _ in }, removeLyrics: { _ in })
    }
    .padding()
    .modelContainer(.emptyPreview)
}
#endif
