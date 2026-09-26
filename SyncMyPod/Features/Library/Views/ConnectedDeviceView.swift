import SwiftData
import SwiftUI

struct ConnectedDeviceView: View {
    let device: IPodDevice

    var body: some View {
        TabView {
            Tab("Library", systemImage: "music.note.list") {
                LibraryView(device: device)
            }
            Tab("Sync", systemImage: "arrow.triangle.2.circlepath") {
                IPodSyncView(device: device)
            }
            Tab("Device", systemImage: "info.circle") {
                DeviceInfoView(device: device)
            }
        }
        .id(device.id)
    }
}

#if DEBUG
#Preview {
    ConnectedDeviceView(device: .preview)
        .environment(\.iTunesDBLoader, .preview)
        .environment(IPodSyncModel())
        .modelContainer(.preview)
}
#endif
