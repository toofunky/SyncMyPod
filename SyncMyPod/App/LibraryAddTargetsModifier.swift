import SwiftData
import SwiftUI

/// Offers each connected device to the library's Add to Device menus while no sync is running.
struct LibraryAddTargetsModifier: ViewModifier {
    @Environment(\.modelContext) private var context
    @Environment(DeviceMountWatcher.self) private var watcher
    @Environment(DeviceSyncModel.self) private var syncModel

    func body(content: Content) -> some View {
        content
            .environment(\.libraryAddTargets, targets)
            .environment(\.isSyncingDevice, syncModel.isSyncing)
    }

    private var targets: [LibraryAddTarget] {
        guard !syncModel.isSyncing else { return [] }
        return watcher.connectedDevices.map { device in
            LibraryAddTarget(id: device.id, name: device.displayName, systemImage: device.systemImage) {
                [syncModel, context] tracks in syncModel.add(tracks, to: device, in: context)
            }
        }
    }
}
