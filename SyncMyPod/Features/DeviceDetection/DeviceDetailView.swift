import SwiftData
import SwiftUI

struct DeviceDetailView: View {
    let deviceID: String?

    @Environment(DeviceMountWatcher.self) private var watcher

    private var device: ConnectedDevice? {
        deviceID.flatMap(watcher.device(withID:))
    }

    var body: some View {
        Group {
            switch device {
            case .iPod(let iPod)?:
                IPodDeviceView(device: iPod)
            case .audioPlayer(let player)?:
                AudioPlayerDeviceView(device: player)
            case nil:
                NoDeviceView()
            }
        }
        .animation(.default, value: device?.id)
    }
}

#if DEBUG
#Preview("Connected") {
    DeviceDetailView(deviceID: IPodDevice.preview.id)
        .environment(DeviceMountWatcher.preview(connectedDevices: [.iPod(.preview)]))
        .environment(\.iTunesDBLoader, .preview)
        .environment(DeviceSyncModel())
        .modelContainer(.preview)
}

#Preview("No Device") {
    DeviceDetailView(deviceID: nil)
        .environment(DeviceMountWatcher.preview())
}
#endif
