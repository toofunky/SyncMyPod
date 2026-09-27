import SwiftUI

struct ShowInPlaylistMenu: View {
    /// Only the playlists that contain the songs.
    let playlists: [LibraryPlaylist]
    let onShow: (LibraryPlaylist) -> Void

    var body: some View {
        Menu("Show in Playlist", systemImage: "music.note.list") {
            if playlists.isEmpty {
                Text("Not in Any Playlist")
            }
            ForEach(playlists) { playlist in
                Button(playlist.name) { onShow(playlist) }
            }
        }
    }
}

#if DEBUG
#Preview {
    ShowInPlaylistMenu(playlists: [.preview], onShow: { _ in })
        .padding()
}
#endif
