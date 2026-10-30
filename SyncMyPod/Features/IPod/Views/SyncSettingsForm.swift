import SwiftData
import SwiftUI

struct SyncSettingsForm: View {
    private static let listedRemovalLimit = 8

    @Bindable var settings: DeviceSyncSettings
    let library: SyncLibrarySnapshot
    let onDevice: ITunesDatabase
    let manifest: LoadedSyncManifest
    let freeBytes: Int64?
    let isSyncing: Bool
    let onSync: (SyncPlan) -> Void
    var onManageStorage: (() -> Void)?

    @State private var plan: SyncPlan?
    @State private var plannedInput: SyncPlanInput?
    @State private var pendingRemoval: SyncPlan?

    private var planInput: SyncPlanInput {
        SyncPlanInput(library: library, selection: settings.selection, onDevice: onDevice, manifest: manifest,
                      makesAudiobookPlaylists: settings.makesAudiobookPlaylists)
    }

    var body: some View {
        VStack(spacing: 0) {
            SyncSelectionEditor(settings: settings, library: library, includesSpokenWord: true)
            Divider()
            let input = planInput
            SyncSummaryBar(totals: plan?.totals, isCalculating: plannedInput != input, freeBytes: freeBytes,
                           isSyncing: isSyncing, onSync: { plan.map(start) }, onManageStorage: onManageStorage)
                .task(id: input) { await replan(input) }
        }
        .confirmationDialog(removalTitle, isPresented: isConfirmingRemoval, presenting: pendingRemoval) { plan in
            Button("Sync and Remove", role: .destructive) { onSync(plan) }
        } message: { plan in
            Text(removalMessage(plan))
        }
    }

    private func replan(_ input: SyncPlanInput) async {
        let newPlan = await input.plan()
        guard !Task.isCancelled else { return }
        plan = newPlan
        plannedInput = input
    }

    private func start(_ plan: SyncPlan) {
        if plan.removals.isEmpty { onSync(plan) } else { pendingRemoval = plan }
    }

    private var isConfirmingRemoval: Binding<Bool> {
        Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } })
    }

    private var removalTitle: String {
        SyncRemovalWording.title(removing: pendingRemoval?.removals ?? [], deviceKind: .iPod)
    }

    private func removalMessage(_ plan: SyncPlan) -> String {
        let reason = "They're no longer selected, their file or download was removed, or they duplicate another song "
            + "on the iPod. Your music library and downloads aren't affected."
        return (SyncRemovalWording.listing(plan.removals, limit: Self.listedRemovalLimit) + [reason])
            .joined(separator: "\n")
    }
}

#if DEBUG
#Preview {
    SyncSettingsForm(settings: DeviceSyncSettings(deviceID: "preview"),
                     library: SyncLibrarySnapshot(tracks: LibraryTrack.previewTracks, playlists: [.preview],
                                                  preservingAlbumArtist: false),
                     onDevice: .preview, manifest: LoadedSyncManifest(), freeBytes: 38_000_000_000, isSyncing: false,
                     onSync: { _ in })
        .modelContainer(.preview)
}
#endif
