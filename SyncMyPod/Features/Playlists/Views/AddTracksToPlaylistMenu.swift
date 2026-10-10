import SwiftData
import SwiftUI

/// Adds the given songs to a playlist, or makes a new playlist of them.
struct AddTracksToPlaylistMenu: View {
    let tracks: [LibraryTrack]
    let playlists: [LibraryPlaylist]

    @Environment(\.modelContext) private var context

    var body: some View {
        AddToPlaylistMenu(playlists: playlists.filter { !$0.isFavorites }, onAdd: add)
            .disabled(tracks.isEmpty)
    }

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
        AddTracksToPlaylistMenu(tracks: [LibraryTrack.previewTracks[0]], playlists: [.preview])
    }
    .padding()
    .modelContainer(.emptyPreview)
}
#endif
