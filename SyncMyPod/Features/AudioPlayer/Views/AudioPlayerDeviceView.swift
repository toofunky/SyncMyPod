import SwiftData
import SwiftUI

struct AudioPlayerDeviceView: View {
    let device: AudioPlayerDevice

    private static let tabBarTopPadding: CGFloat = 10

    var body: some View {
        TabView {
            Tab("Sync", systemImage: "arrow.triangle.2.circlepath") {
                PlayerSyncView(device: device)
            }
            Tab("Settings", systemImage: "gearshape") {
                AudioPlayerSettingsView(device: device)
                    .id(device.config)
            }
        }
        .padding(.top, Self.tabBarTopPadding)
        .id(device.id)
    }
}

#if DEBUG
#Preview {
    AudioPlayerDeviceView(device: .preview)
        .environment(DeviceMountWatcher.preview(connectedDevices: [.audioPlayer(.preview)]))
        .environment(DeviceSyncModel())
        .modelContainer(.preview)
}
#endif
