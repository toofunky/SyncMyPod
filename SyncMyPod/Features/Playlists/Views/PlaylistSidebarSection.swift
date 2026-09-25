import SwiftData
import SwiftUI

struct PlaylistSidebarSection: View {
    @Binding var selection: SidebarItem?

    @Environment(\.modelContext) private var context
    @Query(sort: \LibraryPlaylist.createdAt) private var playlists: [LibraryPlaylist]

    var body: some View {
        Section {
            ForEach(playlists) { playlist in
                Label(playlist.name, systemImage: "music.note.list")
                    .tag(SidebarItem.playlist(playlist.playlistID))
                    .contextMenu {
                        Button("Delete Playlist", systemImage: "trash", role: .destructive) { delete(playlist) }
                    }
            }
        } header: {
            HStack {
                Text("Playlists")
                Spacer()
                Button("New Playlist", systemImage: "plus", action: create)
                    .buttonStyle(.borderless)
                    .labelStyle(.iconOnly)
            }
        }
    }

    private func create() {
        let playlist = LibraryPlaylist()
        context.insert(playlist)
        selection = .playlist(playlist.playlistID)
    }

    private func delete(_ playlist: LibraryPlaylist) {
        if selection == .playlist(playlist.playlistID) { selection = .library }
        context.delete(playlist)
    }
}

#Preview {
    @Previewable @State var selection: SidebarItem? = .library
    List(selection: $selection) {
        PlaylistSidebarSection(selection: $selection)
    }
    .modelContainer(.preview)
}
