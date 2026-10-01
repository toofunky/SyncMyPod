import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(IPodSyncModel.self) private var syncModel
    @State private var selection: SidebarItem? = .library
    @State private var selectedPlaylistID: UUID?
    @State private var libraryModel = MusicLibraryModel()
    @State private var librarySelection = Set<LibraryTrack.ID>()
    @State private var isShowingTagEditor = false

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
                MusicLibraryView(model: libraryModel, selection: $librarySelection, showPlaylist: show)
            }
        }
        .inspector(isPresented: tagEditorPresented) {
            LibraryTagEditorInspector(selection: librarySelection,
                                      isLocked: libraryModel.isScanning || syncModel.isSyncing,
                                      isShowing: $isShowingTagEditor)
        }
        .frame(minWidth: 420, minHeight: 320)
    }

    /// The tag editor only belongs to the music library, so it hides while another section is showing.
    private var tagEditorPresented: Binding<Bool> {
        Binding(get: { isShowingTagEditor && selection == .library },
                set: { isShowingTagEditor = $0 })
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
