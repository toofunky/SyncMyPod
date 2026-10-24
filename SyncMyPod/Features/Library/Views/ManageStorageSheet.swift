import SwiftUI

/// Lists everything on the iPod, whichever app put it there, and removes the songs chosen.
struct ManageStorageSheet: View {
    private static let listedRemovalLimit = 8
    private static let minWidth: CGFloat = 760
    private static let minHeight: CGFloat = 480

    let device: IPodDevice

    @Environment(\.dismiss) private var dismiss
    @Environment(DeviceSyncModel.self) private var syncModel
    @State private var pendingRemoval: [ITunesTrack] = []

    var body: some View {
        LibraryView(device: device, reloadID: syncModel.completedSyncCount, onRemove: { pendingRemoval = $0 },
                    onDone: { dismiss() })
            .frame(minWidth: Self.minWidth, minHeight: Self.minHeight)
            .confirmationDialog(SyncRemovalWording.title(removing: pendingRemoval, deviceKind: "iPod"),
                                isPresented: isConfirmingRemoval) {
                Button("Remove", role: .destructive, action: remove)
            } message: {
                Text(removalMessage)
            }
            .syncProgressSheet()
    }

    private var isConfirmingRemoval: Binding<Bool> {
        Binding(get: { !pendingRemoval.isEmpty }, set: { if !$0 { pendingRemoval = [] } })
    }

    private var removalMessage: String {
        let reason = "Their files are deleted from the iPod. Songs still selected on the Sync tab are copied back the "
            + "next time you sync. Your music library isn't affected."
        return (SyncRemovalWording.listing(pendingRemoval, limit: Self.listedRemovalLimit) + [reason])
            .joined(separator: "\n")
    }

    /// The list reloads once the removal finishes, so more songs can be removed.
    private func remove() {
        syncModel.sync([], removing: Set(pendingRemoval.map(\.databaseID)), to: .iPod(device))
        pendingRemoval = []
    }
}

#if DEBUG
#Preview {
    ManageStorageSheet(device: .preview)
        .environment(\.iTunesDBLoader, .preview)
        .environment(DeviceSyncModel())
}
#endif
