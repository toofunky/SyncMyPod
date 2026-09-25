import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarItem? = .library

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Library") {
                    ForEach(SidebarItem.fixedItems) { item in
                        Label(item.title, systemImage: item.systemImage)
                    }
                }
                PlaylistSidebarSection(selection: $selection)
            }
        } detail: {
            switch selection {
            case .device: DeviceDetectionView()
            case .playlist(let id): PlaylistDetailView(playlistID: id)
            case .library, nil: MusicLibraryView()
            }
        }
        .frame(minWidth: 420, minHeight: 320)
    }
}

#Preview {
    ContentView()
        .environment(IPodMountWatcher.preview(connectedDevice: .preview))
        .environment(IPodSyncModel())
        .environment(\.iTunesDBLoader, .preview)
        .modelContainer(.preview)
}
