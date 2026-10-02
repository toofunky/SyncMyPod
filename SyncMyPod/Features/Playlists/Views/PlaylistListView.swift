import SwiftData
import SwiftUI

struct PlaylistListView: View {
    @Binding var selection: UUID?

    @Environment(\.modelContext) private var context
    @Query(sort: LibraryPlaylist.sidebarOrder) private var playlists: [LibraryPlaylist]

    var body: some View {
        ScrollViewReader { proxy in
            list
                .onAppear {
                    selectFirstIfNeeded()
                    if let selection { proxy.scrollTo(selection, anchor: .center) }
                }
        }
    }

    private var list: some View {
        List(selection: $selection) {
            ForEach(playlists) { playlist in
                Label(playlist.name, systemImage: "music.note.list")
                    .tag(playlist.playlistID)
                    .contextMenu {
                        Button("Delete Playlist", systemImage: "trash", role: .destructive) { delete(playlist) }
                    }
            }
            .onMove { LibraryPlaylist.move(playlists, fromOffsets: $0, toOffset: $1) }
        }
    }

    private func selectFirstIfNeeded() {
        guard selection == nil || !playlists.contains(where: { $0.playlistID == selection }) else { return }
        selection = playlists.first?.playlistID
    }

    private func delete(_ playlist: LibraryPlaylist) {
        if selection == playlist.playlistID { selection = nil }
        context.delete(playlist)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: UUID?
    PlaylistListView(selection: $selection)
        .modelContainer(.preview)
}
#endif
