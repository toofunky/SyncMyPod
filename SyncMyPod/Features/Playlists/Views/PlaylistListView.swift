import SwiftData
import SwiftUI

struct PlaylistListView: View {
    @Binding var selection: UUID?

    @Environment(\.modelContext) private var context
    @Query(sort: LibraryPlaylist.sidebarOrder) private var playlists: [LibraryPlaylist]

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(playlists) { playlist in
                    Label(playlist.name, systemImage: "music.note.list")
                        .tag(playlist.playlistID)
                        .contextMenu {
                            Button("Delete Playlist", systemImage: "trash", role: .destructive) { delete(playlist) }
                        }
                }
                .onMove { LibraryPlaylist.move(playlists, fromOffsets: $0, toOffset: $1) }
            } header: {
                header
            }
        }
        .onAppear(perform: selectFirstIfNeeded)
    }

    private var header: some View {
        HStack {
            Text("Playlists")
            Spacer()
            Button("New Playlist", systemImage: "plus", action: create)
                .buttonStyle(.borderless)
                .labelStyle(.iconOnly)
        }
    }

    private func selectFirstIfNeeded() {
        guard selection == nil || !playlists.contains(where: { $0.playlistID == selection }) else { return }
        selection = playlists.first?.playlistID
    }

    private func create() {
        let playlist = LibraryPlaylist()
        playlist.sortIndex = LibraryPlaylist.nextSortIndex(after: playlists)
        context.insert(playlist)
        selection = playlist.playlistID
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
