import SwiftData
import SwiftUI

struct PlaylistDetailView: View {
    @Query private var playlists: [LibraryPlaylist]
    @Query private var tracks: [LibraryTrack]

    init(playlistID: UUID) {
        _playlists = Query(filter: #Predicate<LibraryPlaylist> { $0.playlistID == playlistID })
    }

    var body: some View {
        if let playlist = playlists.first {
            PlaylistTrackListView(playlist: playlist, entries: PlaylistEntry.entries(of: playlist, in: tracks))
        } else {
            ContentUnavailableView("Playlist Not Found", systemImage: "music.note.list")
        }
    }
}

#if DEBUG
#Preview {
    PlaylistDetailView(playlistID: LibraryPlaylist.preview.playlistID)
        .modelContainer(.preview)
}
#endif
