import SwiftData
import SwiftUI

/// Unfavorites the songs when every one is already a favorite, otherwise favorites them all.
struct FavoriteMenuItem: View {
    let tracks: [LibraryTrack]
    let favorites: LibraryPlaylist?

    @Environment(\.modelContext) private var context

    var body: some View {
        Group {
            if allFavorites {
                Button("Unfavorite", systemImage: "heart.slash") { setFavorite(false) }
            } else {
                Button("Favorite", systemImage: "heart") { setFavorite(true) }
            }
        }
        .disabled(tracks.isEmpty)
    }

    private var allFavorites: Bool {
        guard let favorites, !tracks.isEmpty else { return false }
        return tracks.allSatisfy(favorites.isFavorite)
    }

    private func setFavorite(_ isFavorite: Bool) {
        let playlist = favorites ?? LibraryPlaylist.ensureFavorites(in: context)
        playlist.setFavorite(tracks, isFavorite)
    }
}

#if DEBUG
#Preview {
    Menu("Song") {
        FavoriteMenuItem(tracks: [LibraryTrack.previewTracks[0]], favorites: nil)
    }
    .padding()
    .modelContainer(.emptyPreview)
}
#endif
