import SwiftData
import SwiftUI

struct PlaylistsView: View {
    @Binding var selection: UUID?
    /// Each playlist's selected rows, kept here so they survive switching playlists or sections.
    @Binding var trackSelections: [UUID: Set<PlaylistEntry.ID>]

    @Environment(\.modelContext) private var context
    @Query(sort: LibraryPlaylist.sidebarOrder) private var playlists: [LibraryPlaylist]
    @State private var isImporting = false
    @State private var exportTarget: LibraryPlaylist?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            splitView
        }
        .playlistTransfer(isImporting: $isImporting, exportTarget: $exportTarget, selection: $selection)
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
                Button("New Playlist", systemImage: "plus", action: create)
            }
            .buttonStyle(.borderless)
            .labelStyle(.iconOnly)
        }
        .padding()
    }

    private var splitView: some View {
        HSplitView {
            PlaylistListView(selection: $selection) { exportTarget = $0 }
                .frame(minWidth: 160, idealWidth: 200, maxWidth: 320)
            detail
                .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
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

    private func create() {
        let playlist = LibraryPlaylist()
        playlist.sortIndex = LibraryPlaylist.nextSortIndex(after: playlists)
        context.insert(playlist)
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
