import SwiftData
import SwiftUI

struct PlaylistsView: View {
    private static let listWidthRange = 160.0...320.0
    private static let detailMinWidth = 300.0

    @Binding var selection: UUID?
    /// Each playlist's selected rows, kept here so they survive switching playlists or sections.
    @Binding var trackSelections: [UUID: Set<PlaylistEntry.ID>]

    @Query(sort: LibraryPlaylist.sidebarOrder) private var playlists: [LibraryPlaylist]
    @AppStorage("playlistListWidth") private var listWidth = 200.0
    @State private var model = PlaylistsModel()
    @State private var isImporting = false
    @State private var exportTarget: LibraryPlaylist?
    @State private var newPlaylistTracks: [LibraryTrack]?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            splitView
        }
        .playlistTransfer(model: model, isImporting: $isImporting, exportTarget: $exportTarget,
                          selection: $selection)
        .modifier(NewPlaylistModifier(tracks: $newPlaylistTracks, onCreate: select))
    }

    private var header: some View {
        HStack {
            Text("Playlists")
                .font(.headline)
            Spacer()
            Group {
                Button("Import Playlist…", systemImage: "square.and.arrow.down") { isImporting = true }
                Button("Export Playlist…", systemImage: "square.and.arrow.up", action: exportSelected)
                    .disabled(selection == nil)
                Button("New Playlist", systemImage: "plus") { newPlaylistTracks = [] }
            }
            .buttonStyle(.borderless)
            .labelStyle(.iconOnly)
        }
        .padding()
    }

    private var splitView: some View {
        // Not an HSplitView, which adds the floating sidebar's width to its panes' minimum widths.
        HStack(spacing: 0) {
            PlaylistListView(model: model, selection: $selection) { exportTarget = $0 }
                .frame(width: listWidth)
            ResizableDivider(width: $listWidth, range: Self.listWidthRange)
            detail
                .frame(minWidth: Self.detailMinWidth, maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let selection {
            PlaylistDetailView(playlistID: selection, selection: trackSelection(for: selection))
                .id(selection)
        } else {
            ContentUnavailableView("No Playlist Selected", systemImage: "music.note.list",
                                   description: Text("Select a playlist or create a new one with +."))
        }
    }

    private func select(_ playlist: LibraryPlaylist) {
        selection = playlist.playlistID
    }

    private func exportSelected() {
        exportTarget = playlists.first { $0.playlistID == selection }
    }

    private func trackSelection(for playlistID: UUID) -> Binding<Set<PlaylistEntry.ID>> {
        Binding(get: { trackSelections[playlistID] ?? [] },
                set: { trackSelections[playlistID] = $0 })
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: UUID? = LibraryPlaylist.preview.playlistID
    PlaylistsView(selection: $selection, trackSelections: .constant([:]))
        .modelContainer(.preview)
}
#endif
