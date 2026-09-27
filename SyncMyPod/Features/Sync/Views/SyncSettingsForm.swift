import SwiftData
import SwiftUI

struct SyncSettingsForm: View {
    private static let listedRemovalLimit = 8

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
        SyncPlanInput(library: library, mode: settings.mode, selectedAlbums: settings.selectedAlbums,
                      selectedGenres: settings.selectedGenres, selectedPlaylists: settings.selectedPlaylists,
                      onDevice: onDevice, manifest: manifest)
    }

    var body: some View {
        VStack(spacing: 0) {
            Toggle("Preserve Album Artist?", isOn: $settings.preservesAlbumArtist)
                .help("When a song's artist differs from its album artist, add the artist to the title and use "
                      + "the album artist as the artist on the iPod. Your music files aren't changed.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.horizontal, .top])
            Picker("Sync", selection: $settings.mode) {
                ForEach(SyncMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.radioGroup)
            .horizontalRadioGroupLayout()
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            Divider()
            selection
            Divider()
            let input = planInput
            SyncSummaryBar(plan: plan, isCalculating: plannedInput != input, freeBytes: freeBytes,
                           isSyncing: isSyncing) { plan.map(start) }
                .task(id: input) { await replan(input) }
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
                                   description: Text("Every song and playlist in your music library will be copied "
                                                     + "to the iPod."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .custom:
            SyncCustomSelectionView(artists: library.artists, genres: library.genres,
                                    playlists: library.playlistNodes,
                                    albumSelection: $settings.selectedAlbums,
                                    genreSelection: $settings.selectedGenres,
                                    playlistSelection: $settings.selectedPlaylists)
                .padding(.top)
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
