import SwiftData
import SwiftUI

struct PlaylistDetailView: View {
    @Binding var selection: Set<PlaylistEntry.ID>

    @Query private var playlists: [LibraryPlaylist]
    @Query private var tracks: [LibraryTrack]

    init(playlistID: UUID, selection: Binding<Set<PlaylistEntry.ID>>) {
        _selection = selection
        _playlists = Query(filter: #Predicate<LibraryPlaylist> { $0.playlistID == playlistID })
    }

    var body: some View {
        if let playlist = playlists.first {
            PlaylistTrackListView(playlist: playlist, entries: PlaylistEntry.entries(of: playlist, in: tracks),
                                  selection: $selection)
        } else {
            ContentUnavailableView("Playlist Not Found", systemImage: "music.note.list")
        }
    }
}

#if DEBUG
#Preview {
    PlaylistDetailView(playlistID: LibraryPlaylist.preview.playlistID, selection: .constant([]))
        .modelContainer(.preview)
}
#endif
