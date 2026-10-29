import SwiftData
import SwiftUI

/// A tab for each kind of content, each choosing to sync all, the selected or none of it. Albums and genres share
/// one scope over songs, and a song syncs when either of them, or a synced playlist, selects it.
struct SyncSelectionEditor: View {
    @Bindable var settings: DeviceSyncSettings
    let library: SyncLibrarySnapshot
    var deviceKind = "iPod"
    var includesSpokenWord = false

    @State private var category = SyncCategory.albums

    var body: some View {
        VStack(spacing: 0) {
            Picker("Show", selection: $category) {
                ForEach(categories) { Text(title(for: $0)).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding()
            SyncScopePicker(category: category, scope: scope(for: category))
                .padding([.horizontal, .bottom])
            Divider()
            content
        }
    }

    private var categories: [SyncCategory] {
        includesSpokenWord ? SyncCategory.allCases : SyncCategory.musicCategories
    }

    @ViewBuilder
    private var content: some View {
        let scope = scope(for: category).wrappedValue
        if scope == .selected {
            list
        } else {
            SyncScopeNotice(category: category, scope: scope, deviceKind: deviceKind)
        }
    }

    @ViewBuilder
    private var list: some View {
        switch category {
        case .albums: SyncAlbumTreeView(artists: library.artists, selection: $settings.selectedAlbums)
        case .genres: SyncGenreListView(genres: library.genres, selection: $settings.selectedGenres)
        case .playlists: SyncPlaylistListView(playlists: library.playlistNodes, selection: $settings.selectedPlaylists)
        case .podcasts: SyncPodcastListView(podcasts: library.podcasts, selection: $settings.selectedPodcasts)
        case .audiobooks: SyncAudiobookListView(audiobooks: library.audiobooks,
                                                selection: $settings.selectedAudiobooks)
        }
    }

    private func scope(for category: SyncCategory) -> Binding<SyncScope> {
        switch category {
        case .albums, .genres: $settings.songScope
        case .playlists: $settings.playlistScope
        case .podcasts: $settings.podcastScope
        case .audiobooks: $settings.audiobookScope
        }
    }

    private func title(for category: SyncCategory) -> String {
        switch scope(for: category).wrappedValue {
        case .all: "\(category.title) (All)"
        case .none: category.title
        case .selected:
            selectedCount(in: category) == 0 ? category.title : "\(category.title) (\(selectedCount(in: category)))"
        }
    }

    private func selectedCount(in category: SyncCategory) -> Int {
        switch category {
        case .albums: settings.selectedAlbums.count
        case .genres: settings.selectedGenres.count
        case .playlists: settings.selectedPlaylists.count
        case .podcasts: settings.selectedPodcasts.count
        case .audiobooks: settings.selectedAudiobooks.count
        }
    }
}

#if DEBUG
#Preview {
    let settings = DeviceSyncSettings(deviceID: "preview")
    settings.songScope = .selected
    settings.podcastScope = .none
    return SyncSelectionEditor(settings: settings,
                               library: SyncLibrarySnapshot(tracks: LibraryTrack.previewTracks, playlists: [.preview],
                                                            preservingAlbumArtist: false),
                               includesSpokenWord: true)
        .modelContainer(.preview)
}
#endif
