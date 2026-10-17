import SwiftUI

/// Albums, genres, playlists and podcasts are combined: a song syncs when any of them selects it.
struct SyncCustomSelectionView: View {
    let artists: [SyncArtistNode]
    let genres: [SyncGenreNode]
    let playlists: [SyncPlaylistNode]
    var podcasts: [SyncPodcastSnapshot] = []
    var categories = SyncCategory.musicCategories
    @Binding var albumSelection: Set<String>
    @Binding var genreSelection: Set<String>
    @Binding var playlistSelection: Set<String>
    var podcastSelection: Binding<Set<String>> = .constant([])

    @State private var category = SyncCategory.albums

    var body: some View {
        VStack(spacing: 0) {
            Picker("Show", selection: $category) {
                ForEach(categories) { Text(title(for: $0)).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding([.horizontal, .bottom])
            list
        }
    }

    @ViewBuilder
    private var list: some View {
        switch category {
        case .albums: SyncAlbumTreeView(artists: artists, selection: $albumSelection)
        case .genres: SyncGenreListView(genres: genres, selection: $genreSelection)
        case .playlists: SyncPlaylistListView(playlists: playlists, selection: $playlistSelection)
        case .podcasts: SyncPodcastListView(podcasts: podcasts, selection: podcastSelection)
        }
    }

    private func title(for category: SyncCategory) -> String {
        let count = switch category {
        case .albums: albumSelection.count
        case .genres: genreSelection.count
        case .playlists: playlistSelection.count
        case .podcasts: podcastSelection.wrappedValue.count
        }
        return count == 0 ? category.title : "\(category.title) (\(count))"
    }
}

#Preview {
    @Previewable @State var albums: Set<String> = []
    @Previewable @State var genres: Set<String> = ["Rock"]
    @Previewable @State var playlists: Set<String> = []
    SyncCustomSelectionView(
        artists: [SyncArtistNode(name: "Coldplay", albums: [
            SyncAlbumNode(key: "Coldplay\u{1F}Parachutes", title: "Parachutes", trackCount: 10, byteCount: 82_000_000)
        ])],
        genres: [SyncGenreNode(name: "Rock", trackCount: 21, byteCount: 180_000_000)],
        playlists: [SyncPlaylistNode(key: "road-trip", name: "Road Trip", trackCount: 24)],
        categories: SyncCategory.allCases,
        albumSelection: $albums, genreSelection: $genres, playlistSelection: $playlists)
}
