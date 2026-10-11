import SwiftData
import SwiftUI

/// Context menu items shared by every song list: favorite, then the tag and lyrics items for a single song.
struct SongMenuItems: View {
    let tracks: [LibraryTrack]
    let favorites: LibraryPlaylist?
    let actions: SongMenuActions

    var body: some View {
        FavoriteMenuItem(tracks: tracks, favorites: favorites)
        Divider()
        if let editTags = actions.editTags {
            Button("Edit Tags…", systemImage: "tag") {
                if let track { editTags(track) }
            }
            .disabled(track == nil)
        }
        LyricsMenuItems(track: track, edit: actions.editLyrics, remove: actions.removeLyrics)
    }

    private var track: LibraryTrack? {
        tracks.count == 1 ? tracks.first : nil
    }
}

#if DEBUG
#Preview {
    Menu("Song") {
        SongMenuItems(tracks: [LibraryTrack.previewTracks[0]], favorites: nil,
                      actions: SongMenuActions(editTags: { _ in }))
    }
    .padding()
    .modelContainer(.emptyPreview)
}
#endif
