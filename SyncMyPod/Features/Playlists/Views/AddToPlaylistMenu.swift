import SwiftUI

struct AddToPlaylistMenu: View {
    let playlists: [LibraryPlaylist]
    /// `nil` asks for a new playlist.
    let onAdd: (LibraryPlaylist?) -> Void

    var body: some View {
        Menu("Add to Playlist", systemImage: "text.badge.plus") {
            Button("New Playlist") { onAdd(nil) }
            if !playlists.isEmpty {
                Divider()
            }
            ForEach(playlists) { playlist in
                Button(playlist.name) { onAdd(playlist) }
            }
        }
    }
}

#if DEBUG
#Preview {
    AddToPlaylistMenu(playlists: [.preview], onAdd: { _ in })
        .padding()
}
#endif
