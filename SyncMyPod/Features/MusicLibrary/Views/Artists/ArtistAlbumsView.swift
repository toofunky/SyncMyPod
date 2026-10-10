import SwiftData
import SwiftUI

/// Every album by one artist, each followed by its songs.
struct ArtistAlbumsView: View {
    let artistName: String
    let sections: [ArtistAlbumSection]
    @Binding var sortOrder: AlbumSortOrder
    var showPlaylist: ((LibraryPlaylist) -> Void)?

    @Environment(MusicPlayerModel.self) private var player: MusicPlayerModel?
    @Query(sort: LibraryPlaylist.sidebarOrder) private var playlists: [LibraryPlaylist]
    @State private var lyricsTrack: LibraryTrack?
    @State private var lyricsTrackToRemove: LibraryTrack?

    var body: some View {
        VStack(spacing: 0) {
            header
            albumList
        }
        .modifier(LyricsEditingModifier(editing: $lyricsTrack, removing: $lyricsTrackToRemove))
    }

    private var header: some View {
        HStack {
            Text(artistName)
                .font(.title.bold())
                .lineLimit(1)
            Spacer()
            Picker("Sort By", selection: $sortOrder) {
                ForEach(ArtistAlbumSection.sortOrders) { Text($0.title).tag($0) }
            }
            .pickerStyle(.menu)
            .fixedSize()
            .controlSize(.small)
        }
        .padding()
    }

    private var albumList: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(sections) { section in
                    ArtistAlbumRow(section: section, onPlay: play, playlists: playlists,
                                   editLyrics: { lyricsTrack = $0 }, removeLyrics: { lyricsTrackToRemove = $0 },
                                   showPlaylist: showPlaylist)
                        .padding(.vertical)
                    if section.id != sections.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    /// Plays on through the rest of the album and then the albums below it.
    private func play(_ track: LibraryTrack) {
        let tracks = sections.flatMap(\.tracks)
        guard let index = tracks.firstIndex(where: { $0.id == track.id }) else { return }
        player?.play(tracks, startingAt: index)
    }
}

#if DEBUG
#Preview {
    ArtistAlbumsView(artistName: "OutKast", sections: ArtistAlbumSection.sections(from: LibraryTrack.previewTracks),
                     sortOrder: .constant(.year))
        .frame(width: 500, height: 600)
        .environment(DeviceMountWatcher.preview())
        .environment(DeviceSyncModel())
        .modelContainer(.preview)
}
#endif
