import SwiftData
import SwiftUI

struct SyncSettingsForm: View {
    private static let listedRemovalLimit = 8

    @Bindable var settings: IPodSyncSettings
    let tracks: [LibraryTrack]
    let onDevice: [ITunesTrack]
    let freeBytes: Int64?
    let isSyncing: Bool
    let onSync: (SyncPlan) -> Void

    @State private var pendingRemoval: SyncPlan?

    private var plan: SyncPlan {
        SyncPlan.make(tracks: tracks, mode: settings.mode, selectedAlbums: settings.selectedAlbums,
                      onDevice: onDevice)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Sync", selection: $settings.mode) {
                ForEach(SyncMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding()
            Divider()
            selection
            Divider()
            let plan = plan
            SyncSummaryBar(plan: plan, freeBytes: freeBytes, isSyncing: isSyncing) { start(plan) }
        }
        .confirmationDialog(removalTitle, isPresented: isConfirmingRemoval, presenting: pendingRemoval) { plan in
            Button("Sync and Remove", role: .destructive) { onSync(plan) }
        } message: { plan in
            Text(removalMessage(plan))
        }
    }

    @ViewBuilder
    private var selection: some View {
        switch settings.mode {
        case .allSongs:
            ContentUnavailableView("All Songs", systemImage: "music.note.list",
                                   description: Text("Every song in your music library will be copied to the iPod."))
        case .custom:
            SyncSelectionTreeView(artists: SyncTreeBuilder.artists(from: tracks),
                                  selection: $settings.selectedAlbums)
        }
    }

    private func start(_ plan: SyncPlan) {
        if plan.removals.isEmpty { onSync(plan) } else { pendingRemoval = plan }
    }

    private var isConfirmingRemoval: Binding<Bool> {
        Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } })
    }

    private var removalTitle: String {
        let count = pendingRemoval?.removals.count ?? 0
        return "Remove \(count) \(count == 1 ? "song" : "songs") from the iPod?"
    }

    private func removalMessage(_ plan: SyncPlan) -> String {
        let listed = plan.removals.prefix(Self.listedRemovalLimit).map { "\($0.title) — \($0.artist)" }
        let remainder = plan.removals.count - listed.count
        let more = remainder > 0 ? ["and \(remainder) more"] : []
        return (listed + more + ["They're no longer selected. Your music library isn't affected."])
            .joined(separator: "\n")
    }
}

#Preview {
    SyncSettingsForm(settings: IPodSyncSettings(deviceID: "preview"), tracks: LibraryTrack.previewTracks,
                     onDevice: [], freeBytes: 38_000_000_000, isSyncing: false, onSync: { _ in })
        .modelContainer(.preview)
}
