import SwiftData
import SwiftUI

/// Chooses between syncing everything and a custom selection of albums, genres and playlists.
struct SyncSelectionEditor: View {
    @Bindable var settings: IPodSyncSettings
    let library: SyncLibrarySnapshot
    var deviceKind = "iPod"

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
                                   description: Text("Every song and playlist in your music library will be copied "
                                                     + "to the \(deviceKind)."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .custom:
            SyncCustomSelectionView(artists: library.artists, genres: library.genres,
                                    playlists: library.playlistNodes,
                                    albumSelection: $settings.selectedAlbums,
                                    genreSelection: $settings.selectedGenres,
                                    playlistSelection: $settings.selectedPlaylists)
                .padding(.top)
        }
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
