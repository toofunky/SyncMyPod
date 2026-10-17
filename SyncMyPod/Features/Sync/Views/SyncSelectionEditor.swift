import SwiftData
import SwiftUI

/// Chooses between syncing everything and a custom selection of albums, genres, playlists and, for players,
/// podcasts.
struct SyncSelectionEditor: View {
    @Bindable var settings: IPodSyncSettings
    let library: SyncLibrarySnapshot
    var deviceKind = "iPod"
    var includesPodcasts = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("Sync", selection: $settings.mode) {
                ForEach(SyncMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.radioGroup)
            .horizontalRadioGroupLayout()
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            Divider()
            selection
        }
    }

    @ViewBuilder
    private var selection: some View {
        switch settings.mode {
        case .allSongs:
            ContentUnavailableView("All Songs", systemImage: "music.note.list",
                                   description: Text(allSongsDescription))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .custom:
            SyncCustomSelectionView(artists: library.artists, genres: library.genres,
                                    playlists: library.playlistNodes, podcasts: library.podcasts,
                                    categories: includesPodcasts ? SyncCategory.allCases : SyncCategory.musicCategories,
                                    albumSelection: $settings.selectedAlbums,
                                    genreSelection: $settings.selectedGenres,
                                    playlistSelection: $settings.selectedPlaylists,
                                    podcastSelection: $settings.selectedPodcasts)
                .padding(.top)
        }
    }

    private var allSongsDescription: String {
        let contents = includesPodcasts ? "song, playlist and downloaded podcast episode"
            : "song and playlist in your music library"
        return "Every \(contents) will be copied to the \(deviceKind)."
    }
}

#if DEBUG
#Preview {
    SyncSelectionEditor(settings: IPodSyncSettings(deviceID: "preview"),
                        library: SyncLibrarySnapshot(tracks: LibraryTrack.previewTracks, playlists: [.preview],
                                                     preservingAlbumArtist: false))
        .modelContainer(.preview)
}
#endif
