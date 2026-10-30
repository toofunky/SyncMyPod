import SwiftData
import SwiftUI

struct PlayerSyncForm: View {
    private static let listedRemovalLimit = 8

    @Bindable var settings: DeviceSyncSettings
    let library: SyncLibrarySnapshot
    let contents: PlayerDeviceContents
    let config: AudioPlayerConfig
    let missingSources: Set<String>
    var sidecars = LibrarySidecars()
    let freeBytes: Int64?
    let isSyncing: Bool
    let onSync: (PlayerSyncPlan) -> Void

    @State private var plan: PlayerSyncPlan?
    @State private var plannedInput: PlayerPlanInput?
    @State private var pendingRemoval: PlayerSyncPlan?

    private var planInput: PlayerPlanInput {
        PlayerPlanInput(library: library, selection: settings.selection, contents: contents, config: config,
                        missingSources: missingSources, sidecars: sidecars)
    }

    var body: some View {
        VStack(spacing: 0) {
            SyncSelectionEditor(settings: settings, library: library, deviceKind: .player, includesSpokenWord: true)
            Divider()
            let input = planInput
            SyncSummaryBar(totals: plan?.totals, deviceKind: .player, isCalculating: plannedInput != input,
                           freeBytes: freeBytes, isSyncing: isSyncing) { plan.map(start) }
                .task(id: input) { await replan(input) }
        }
        .confirmationDialog(removalTitle, isPresented: isConfirmingRemoval, presenting: pendingRemoval) { plan in
            Button("Sync and Remove", role: .destructive) { onSync(plan) }
        } message: { plan in
            Text(removalMessage(plan))
        }
    }

    private func replan(_ input: PlayerPlanInput) async {
        let newPlan = await input.plan()
        guard !Task.isCancelled else { return }
        plan = newPlan
        plannedInput = input
    }

    private func start(_ plan: PlayerSyncPlan) {
        if plan.removals.isEmpty { onSync(plan) } else { pendingRemoval = plan }
    }

    private var isConfirmingRemoval: Binding<Bool> {
        Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } })
    }

    /// Episodes and audiobook files are told apart by their folder, unless it's shared with the music folder or
    /// is the root.
    private var removalTitle: String {
        let removals = pendingRemoval?.removals ?? []
        let episodes = count(removals, in: config.podcastPath)
        let books = config.audiobookPath == config.podcastPath ? 0 : count(removals, in: config.audiobookPath)
        return SyncRemovalWording.title(songs: removals.count - episodes - books, episodes: episodes,
                                        audiobookFiles: books, deviceKind: .player)
    }

    private func count(_ removals: [PlayerFileRemoval], in folder: String) -> Int {
        guard !folder.isEmpty, folder != config.musicPath else { return 0 }
        return removals.count { $0.path.hasPrefix(folder + "/") }
    }

    private func removalMessage(_ plan: PlayerSyncPlan) -> String {
        let listed = plan.removals.prefix(Self.listedRemovalLimit).map(\.fileName)
        let remainder = plan.removals.count - listed.count
        let more = remainder > 0 ? ["and \(remainder) more"] : []
        let reason = "They're no longer selected or their file or download was removed. Only what SyncMyPod copied "
            + "is removed, and your music library and downloads aren't affected."
        return (listed + more + [reason]).joined(separator: "\n")
    }
}

#if DEBUG
#Preview {
    PlayerSyncForm(settings: DeviceSyncSettings(deviceID: "preview"),
                   library: SyncLibrarySnapshot(tracks: LibraryTrack.previewTracks, playlists: [.preview],
                                                preservingAlbumArtist: false),
                   contents: PlayerDeviceContents(), config: AudioPlayerDevice.preview.config, missingSources: [],
                   freeBytes: 198_000_000_000, isSyncing: false, onSync: { _ in })
        .modelContainer(.preview)
}
#endif
