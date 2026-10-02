import SwiftData
import SwiftUI

struct PlaylistTrackListView: View {
    @Bindable var playlist: LibraryPlaylist
    let entries: [PlaylistEntry]

    @Binding var selection: Set<PlaylistEntry.ID>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PlaylistHeaderView(playlist: playlist, entries: entries)
            Divider()
            if entries.isEmpty {
                ContentUnavailableView("No Songs", systemImage: "music.note",
                                       description: Text("Add songs from Music Library with “Add to Playlist”."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                trackList
            }
        }
    }

    private var trackList: some View {
        ScrollViewReader { proxy in
            list
                .onAppear {
                    guard let first = selection.filter({ $0 < entries.count }).min() else { return }
                    proxy.scrollTo(first, anchor: .center)
                }
        }
    }

    private var list: some View {
        List(selection: $selection) {
            ForEach(entries) { PlaylistTrackRow(entry: $0) }
                .onMove { offsets, destination in
                    playlist.trackPaths.move(fromOffsets: offsets, toOffset: destination)
                    selection = []
                }
        }
        .contextMenu(forSelectionType: PlaylistEntry.ID.self) { ids in
            Button("Remove from Playlist", systemImage: "minus.circle") { remove(ids) }
                .disabled(ids.isEmpty)
        }
        .onDeleteCommand { remove(selection) }
    }

    private func remove(_ ids: Set<PlaylistEntry.ID>) {
        playlist.trackPaths.remove(atOffsets: IndexSet(ids))
        selection = []
    }
}

#if DEBUG
#Preview {
    let playlist = LibraryPlaylist.preview
    PlaylistTrackListView(playlist: playlist,
                          entries: PlaylistEntry.entries(of: playlist, in: LibraryTrack.previewTracks),
                          selection: .constant([]))
        .modelContainer(.emptyPreview)
}
#endif
