import SwiftUI

struct AppSidebar: View {
    @Binding var selection: SidebarItem?

    @Environment(DeviceMountWatcher.self) private var watcher

    var body: some View {
        List(selection: $selection) {
            ForEach(SidebarItem.libraryItems) { item in
                Label(item.title, systemImage: item.systemImage)
            }
            Section("Devices") {
                if watcher.connectedDevices.isEmpty {
                    Label(SidebarItem.noDevice.title, systemImage: SidebarItem.noDevice.systemImage)
                        .foregroundStyle(.secondary)
                        .tag(SidebarItem.noDevice)
                } else {
                    ForEach(watcher.connectedDevices) { device in
                        DeviceSidebarRow(device: device)
                            .tag(SidebarItem.device(id: device.id))
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            BuyMeACoffeeButton()
                .padding()
        }
        .onChange(of: watcher.connectedDevices.map(\.id)) { _, ids in
            selection = SidebarItem.fallback(for: selection, connectedIDs: ids)
        }
    }
}

#if DEBUG
#Preview("Two Devices") {
    AppSidebar(selection: .constant(.device(id: IPodDevice.preview.id)))
        .environment(DeviceMountWatcher.preview(connectedDevices: [.iPod(.preview), .iPod(.previewNano)]))
        .environment(DeviceSyncModel())
        .frame(width: 220, height: 400)
}

#Preview("No Device") {
    AppSidebar(selection: .constant(.noDevice))
        .environment(DeviceMountWatcher.preview())
        .environment(DeviceSyncModel())
        .frame(width: 220, height: 400)
}
#endif
