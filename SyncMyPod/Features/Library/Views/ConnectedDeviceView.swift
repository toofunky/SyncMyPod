import SwiftUI

struct ConnectedDeviceView: View {
    let device: IPodDevice

    var body: some View {
        TabView {
            Tab("Library", systemImage: "music.note.list") {
                LibraryView(device: device)
            }
            Tab("Device", systemImage: "info.circle") {
                DeviceInfoView(device: device)
            }
        }
        .id(device.id)
    }
}

#Preview {
    ConnectedDeviceView(device: .preview)
        .environment(\.iTunesDBLoader, .preview)
}
