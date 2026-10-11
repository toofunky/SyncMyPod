import SwiftData
import SwiftUI

struct AlbumTracksInspector: View {
    private static let minWidth = 260.0
    private static let idealWidth = 300.0
    private static let maxWidth = 420.0

    let albumID: LibraryAlbum.ID?
    @Binding var isShowing: Bool
    var showPlaylist: ((LibraryPlaylist) -> Void)?

    @Environment(MusicPlayerModel.self) private var player: MusicPlayerModel?
    @Query private var tracks: [LibraryTrack]
    @Query(sort: LibraryPlaylist.sidebarOrder) private var playlists: [LibraryPlaylist]
    @State private var albumTracks: [LibraryTrack] = []
    @State private var tagsTracks: [LibraryTrack]?
    @State private var lyricsTrack: LibraryTrack?
    @State private var lyricsTrackToRemove: LibraryTrack?
    @State private var newPlaylistTracks: [LibraryTrack]?

    var body: some View {
        content
            .inspectorColumnWidth(min: Self.minWidth, ideal: Self.idealWidth, max: Self.maxWidth)
            .toolbar {
                Spacer()
                Button("Album Tracks", systemImage: "sidebar.trailing") { isShowing.toggle() }
                    .disabled(albumID == nil)
            }
            .modifier(TagEditingModifier(tracks: $tagsTracks))
            .modifier(LyricsEditingModifier(editing: $lyricsTrack, removing: $lyricsTrackToRemove))
            .modifier(NewPlaylistModifier(tracks: $newPlaylistTracks))
            .onChange(of: albumID, initial: true) { updateAlbumTracks() }
            .onChange(of: tracks) { updateAlbumTracks() }
            .onModelContextSave { updateAlbumTracks() }
    }

    @ViewBuilder
    private var content: some View {
        if let albumID, !albumTracks.isEmpty {
            List {
                AlbumTracksHeader(album: LibraryAlbum(key: albumID, tracks: albumTracks),
                                  duration: albumTracks.reduce(0) { $0 + $1.duration })
                ForEach(discNumbers, id: \.self) { disc in
                    discSection(disc)
                }
            }
        } else {
            ContentUnavailableView("No Album Selected", systemImage: "square.stack",
                                   description: Text("Click an album to see its songs."))
        }
    }

    @ViewBuilder
    private func discSection(_ disc: Int) -> some View {
        let rows = ForEach(albumTracks.filter { $0.discNumber == disc }) { track in
            AlbumTrackRow(track: track, albumArtist: albumTracks[0].syncArtist)
                .contentShape(.rect)
                .onTapGesture(count: 2) { play(track) }
                .contextMenu {
                    LibrarySongContextMenu(tracks: [track], playlists: playlists, actions: songActions)
                }
        }
        if discNumbers.count > 1 {
            Section(disc > 0 ? "Disc \(disc)" : "Other") { rows }
        } else {
            Section { rows }
        }
    }

    private var songActions: SongMenuActions {
        SongMenuActions(editTags: { tagsTracks = $0 }, editLyrics: { lyricsTrack = $0 },
                        removeLyrics: { lyricsTrackToRemove = $0 }, newPlaylist: { newPlaylistTracks = $0 },
                        showPlaylist: showPlaylist)
    }

    private var discNumbers: [Int] {
        var seen = Set<Int>()
        return albumTracks.map(\.discNumber).filter { seen.insert($0).inserted }
    }

    private func play(_ track: LibraryTrack) {
        guard let index = albumTracks.firstIndex(where: { $0.id == track.id }) else { return }
        player?.play(albumTracks, startingAt: index)
    }

    private func updateAlbumTracks() {
        guard let albumID else { return albumTracks = [] }
        albumTracks = LibraryTrack.albumOrdered(tracks.filter { $0.syncAlbumKey == albumID })
    }
}

#if DEBUG
#Preview {
    @Previewable @State var isShowing = true
    AlbumTracksInspector(albumID: LibraryAlbum.preview.id, isShowing: $isShowing)
        .environment(DeviceMountWatcher.preview())
        .environment(DeviceSyncModel())
        .modelContainer(.preview)
}
#endif
