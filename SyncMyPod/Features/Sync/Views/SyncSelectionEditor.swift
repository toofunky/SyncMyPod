import SwiftData
import SwiftUI

/// Chooses between syncing everything and a custom selection of albums, genres, playlists and, when the device
/// takes them, podcasts and audiobooks.
struct SyncSelectionEditor: View {
    @Bindable var settings: IPodSyncSettings
    let library: SyncLibrarySnapshot
    var deviceKind = "iPod"
    var includesSpokenWord = false

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
                                    audiobooks: library.audiobooks,
                                    categories: includesSpokenWord ? SyncCategory.allCases
                                        : SyncCategory.musicCategories,
                                    albumSelection: $settings.selectedAlbums,
                                    genreSelection: $settings.selectedGenres,
                                    playlistSelection: $settings.selectedPlaylists,
                                    podcastSelection: $settings.selectedPodcasts,
                                    audiobookSelection: $settings.selectedAudiobooks)
                .padding(.top)
        }
    }

    private var allSongsDescription: String {
        let contents = includesSpokenWord ? "song, playlist, downloaded podcast episode and audiobook"
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
