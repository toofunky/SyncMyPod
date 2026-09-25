import SwiftUI

struct ContentView: View {
    var body: some View {
        DeviceDetectionView()
            .frame(minWidth: 420, minHeight: 320)
    }
}

#Preview {
    ContentView()
        .environment(IPodMountWatcher.preview(connectedDevice: .preview))
        .environment(\.iTunesDBLoader, .preview)
}
