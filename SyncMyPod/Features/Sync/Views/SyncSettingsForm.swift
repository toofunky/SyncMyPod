import SwiftData
import SwiftUI

struct SyncSettingsForm: View {
    private static let listedRemovalLimit = 8
    private static let preserveAlbumArtistInfo = "When a song's artist differs from its album artist, the song is "
        + "filed under the album artist on the iPod and the guest artist is added to the title — for example, "
        + "\"Song — Guest Artist\". This keeps albums together when you browse by artist. Your music files "
        + "aren't changed."

    @Bindable var settings: IPodSyncSettings
    let library: SyncLibrarySnapshot
    let onDevice: ITunesDatabase
    let manifest: LoadedSyncManifest
    let freeBytes: Int64?
    let isSyncing: Bool
    let onSync: (SyncPlan) -> Void

    @State private var plan: SyncPlan?
    @State private var plannedInput: SyncPlanInput?
    @State private var pendingRemoval: SyncPlan?

    private var planInput: SyncPlanInput {
        SyncPlanInput(library: library, selection: settings.selection, onDevice: onDevice, manifest: manifest)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Toggle("Preserve Album Artist?", isOn: $settings.preservesAlbumArtist)
                InfoPopoverButton(title: "Preserve Album Artist", message: Self.preserveAlbumArtistInfo)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.horizontal, .top])
            SyncSelectionEditor(settings: settings, library: library)
            Divider()
            let input = planInput
            SyncSummaryBar(totals: plan?.totals, isCalculating: plannedInput != input, freeBytes: freeBytes,
                           isSyncing: isSyncing) { plan.map(start) }
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
        let count = pendingRemoval?.removals.count ?? 0
        return "Remove \(count) \(count == 1 ? "song" : "songs") from the iPod?"
    }

    private func removalMessage(_ plan: SyncPlan) -> String {
        let listed = plan.removals.prefix(Self.listedRemovalLimit).map { "\($0.title) — \($0.artist)" }
        let remainder = plan.removals.count - listed.count
        let more = remainder > 0 ? ["and \(remainder) more"] : []
        let reason = "They're no longer selected, their file was deleted, or they duplicate another song on the iPod. "
            + "Your music library isn't affected."
        return (listed + more + [reason]).joined(separator: "\n")
    }
}

#if DEBUG
#Preview {
    SyncSettingsForm(settings: IPodSyncSettings(deviceID: "preview"),
                     library: SyncLibrarySnapshot(tracks: LibraryTrack.previewTracks, playlists: [.preview],
                                                  preservingAlbumArtist: false),
                     onDevice: .preview, manifest: LoadedSyncManifest(), freeBytes: 38_000_000_000, isSyncing: false,
                     onSync: { _ in })
        .modelContainer(.preview)
}
#endif
