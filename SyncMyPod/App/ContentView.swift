import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarItem? = .library

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.title, systemImage: item.systemImage)
            }
        } detail: {
            switch selection {
            case .device: DeviceDetectionView()
            case .library, nil: MusicLibraryView()
            }
        }
        .frame(minWidth: 420, minHeight: 320)
    }
}

#Preview {
    ContentView()
        .environment(IPodMountWatcher.preview(connectedDevice: .preview))
        .environment(\.iTunesDBLoader, .preview)
        .modelContainer(.preview)
}
