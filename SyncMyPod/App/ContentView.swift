import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarItem? = .library
    @State private var selectedPlaylistID: UUID?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(SidebarItem.fixedItems) { item in
                    if item == .device {
                        DeviceSidebarRow()
                    } else {
                        Label(item.title, systemImage: item.systemImage)
                    }
                }
            }
        } detail: {
            switch selection {
            case .device: DeviceDetectionView()
            case .playlists: PlaylistsView(selection: $selectedPlaylistID)
            case .library, nil:
                MusicLibraryView(showPlaylist: show)
            }
        }
        .frame(minWidth: 420, minHeight: 320)
    }

    private func show(_ playlist: LibraryPlaylist) {
        selectedPlaylistID = playlist.playlistID
        selection = .playlists
    }
}

#if DEBUG
#Preview {
    ContentView()
        .environment(IPodMountWatcher.preview(connectedDevice: .preview))
        .environment(IPodSyncModel())
        .environment(\.iTunesDBLoader, .preview)
        .modelContainer(.preview)
}
#endif
