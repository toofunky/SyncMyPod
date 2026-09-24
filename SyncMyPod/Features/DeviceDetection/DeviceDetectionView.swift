import SwiftUI

struct DeviceDetectionView: View {
    @Environment(IPodMountWatcher.self) private var watcher

    var body: some View {
        Group {
            if let device = watcher.connectedDevice {
                DeviceInfoView(device: device)
            } else {
                NoDeviceView()
            }
        }
        .animation(.default, value: watcher.connectedDevice?.id)
    }
}

#Preview("Connected") {
    DeviceDetectionView()
        .environment(IPodMountWatcher.preview(connectedDevice: .preview))
}

#Preview("No Device") {
    DeviceDetectionView()
        .environment(IPodMountWatcher.preview())
}
