import SwiftUI

struct DeviceSidebarRow: View {
    @Environment(IPodMountWatcher.self) private var watcher
    @Environment(IPodSyncModel.self) private var syncModel
    @State private var ejectError: String?

    var body: some View {
        HStack {
            Label(SidebarItem.device.title, systemImage: SidebarItem.device.systemImage)
            Spacer()
            if watcher.connectedDevice != nil {
                ejectButton
            }
        }
        .alert("Couldn't Eject iPod", isPresented: isShowingError, presenting: ejectError) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
    }

    private var ejectButton: some View {
        Button("Eject iPod", systemImage: "eject.fill", action: eject)
            .buttonStyle(.borderless)
            .labelStyle(.iconOnly)
            .disabled(syncModel.isSyncing || watcher.isEjecting)
            .help(syncModel.isSyncing ? "Can't eject while a sync is in progress" : "Eject iPod")
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { ejectError != nil }, set: { if !$0 { ejectError = nil } })
    }

    private func eject() {
        Task {
            do {
                try await watcher.ejectConnectedDevice()
            } catch {
                ejectError = error.localizedDescription
            }
        }
    }
}

#if DEBUG
#Preview("Connected") {
    List {
        DeviceSidebarRow()
    }
    .environment(IPodMountWatcher.preview(connectedDevice: .preview))
    .environment(IPodSyncModel())
}

#Preview("No Device") {
    List {
        DeviceSidebarRow()
    }
    .environment(IPodMountWatcher.preview())
    .environment(IPodSyncModel())
}
#endif
