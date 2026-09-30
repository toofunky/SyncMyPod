import SwiftData
import SwiftUI

struct PlaylistsView: View {
    @Binding var selection: UUID?

    var body: some View {
        HSplitView {
            PlaylistListView(selection: $selection)
                .frame(minWidth: 160, idealWidth: 200, maxWidth: 320)
            detail
                .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let selection {
            PlaylistDetailView(playlistID: selection)
                .id(selection)
        } else {
            ContentUnavailableView("No Playlist Selected", systemImage: "music.note.list",
                                   description: Text("Select a playlist or create a new one with +."))
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: UUID? = LibraryPlaylist.preview.playlistID
    PlaylistsView(selection: $selection)
        .modelContainer(.preview)
}
#endif
