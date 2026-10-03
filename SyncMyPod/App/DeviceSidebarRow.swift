import SwiftUI

struct DeviceSidebarRow: View {
    let device: ConnectedDevice

    @Environment(DeviceMountWatcher.self) private var watcher
    @Environment(DeviceSyncModel.self) private var syncModel
    @State private var ejectError: String?

    var body: some View {
        HStack {
            Label(device.displayName, systemImage: device.systemImage)
            Spacer()
            if device.isEjectable {
                ejectButton
            }
        }
        .alert("Couldn't Eject \(device.kindName.deviceKindTitle)", isPresented: isShowingError, presenting: ejectError) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
    }

    private var isSyncingThisDevice: Bool { syncModel.syncingDeviceID == device.id }

    private var ejectButton: some View {
        Button("Eject \(device.displayName)", systemImage: "eject.fill", action: eject)
            .buttonStyle(.borderless)
            .labelStyle(.iconOnly)
            .disabled(isSyncingThisDevice || watcher.ejectingDeviceIDs.contains(device.id))
            .help(isSyncingThisDevice ? "Can't eject while a sync is in progress" : "Eject \(device.displayName)")
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { ejectError != nil }, set: { if !$0 { ejectError = nil } })
    }

    private func eject() {
        Task {
            do {
                try await watcher.eject(device)
            } catch {
                ejectError = error.localizedDescription
            }
        }
    }
}

#if DEBUG
#Preview {
    List(ConnectedDevice.previewDevices) { device in
        DeviceSidebarRow(device: device)
    }
    .environment(DeviceMountWatcher.preview(connectedDevices: [.iPod(.preview)]))
    .environment(DeviceSyncModel())
}
#endif
