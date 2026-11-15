import AppKit
import SwiftData
import SwiftUI

/// The right-click menu for library songs, given in the order shown.
struct LibraryTrackContextMenu: View {
    let tracks: [LibraryTrack]
    let playlists: [LibraryPlaylist]
    let actions: SongMenuActions

    @Environment(\.libraryAddTargets) private var addTargets

    var body: some View {
        AddToDeviceMenu(targets: addTargets) { $0.add(tracks) }
            .disabled(addTargets.isEmpty || tracks.isEmpty)
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

    /// `nil` asks for a name for a new playlist of the songs; songs already in the playlist ask first.
    private func addToPlaylist(_ playlist: LibraryPlaylist?) {
        guard let playlist else {
            actions.newPlaylist(tracks)
            return
        }
        let addition = PlaylistAddition(tracks: tracks, playlist: playlist)
        if addition.duplicates.isEmpty {
            addition.addAll()
        } else {
            actions.confirmDuplicates(addition)
        }
    }

    private func showInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting(tracks.map { URL(filePath: $0.filePath) })
    }
}

#if DEBUG
#Preview {
    Menu("Song") {
        LibraryTrackContextMenu(tracks: [LibraryTrack.previewTracks[0]], playlists: [.preview], actions: SongMenuActions())
    }
    .padding()
    .environment(\.libraryAddTargets, LibraryAddTarget.previews)
    .modelContainer(.emptyPreview)
}
#endif
