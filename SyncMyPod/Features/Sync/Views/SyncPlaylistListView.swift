import SwiftUI

struct SyncPlaylistListView: View {
    let playlists: [SyncPlaylistNode]
    @Binding var selection: Set<String>

    var body: some View {
        if playlists.isEmpty {
            ContentUnavailableView("No Playlists", systemImage: "music.note.list",
                                   description: Text("Create a playlist in Music Library to sync it."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(playlists) { playlist in
                Toggle(isOn: $selection.contains(playlist.key)) {
                    SyncRowLabel(title: playlist.name, systemImage: "music.note.list",
                                 detail: SyncRowLabel.detail(trackCount: playlist.trackCount))
                }
            }
            .toggleStyle(.checkbox)
        }
    }
}

#Preview {
    @Previewable @State var selection: Set<String> = ["road-trip"]
    SyncPlaylistListView(playlists: [
        SyncPlaylistNode(key: "road-trip", name: "Road Trip", trackCount: 24),
        SyncPlaylistNode(key: "workout", name: "Workout", trackCount: 40)
    ], selection: $selection)
}
