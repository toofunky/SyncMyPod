import SwiftData
import SwiftUI

/// Context menu items shared by every song list: favorite, then the lyrics items for a single song.
struct SongMenuItems: View {
    let tracks: [LibraryTrack]
    let favorites: LibraryPlaylist?
    let editLyrics: (LibraryTrack) -> Void
    let removeLyrics: (LibraryTrack) -> Void

    var body: some View {
        FavoriteMenuItem(tracks: tracks, favorites: favorites)
        Divider()
        LyricsMenuItems(track: tracks.count == 1 ? tracks.first : nil, edit: editLyrics, remove: removeLyrics)
    }
}

#if DEBUG
#Preview {
    Menu("Song") {
        SongMenuItems(tracks: [LibraryTrack.previewTracks[0]], favorites: nil,
                      editLyrics: { _ in }, removeLyrics: { _ in })
    }
    .padding()
    .modelContainer(.emptyPreview)
}
#endif
