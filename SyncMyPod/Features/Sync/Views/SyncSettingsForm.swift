import SwiftData
import SwiftUI

struct SyncSettingsForm: View {
    @Bindable var settings: IPodSyncSettings
    let tracks: [LibraryTrack]
    let onDevice: Set<IPodTrackMatchKey>
    let freeBytes: Int64?
    let isSyncing: Bool
    let onSync: (SyncPlan) -> Void

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
            SyncSummaryBar(plan: plan, freeBytes: freeBytes, isSyncing: isSyncing) { onSync(plan) }
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
}

#Preview {
    SyncSettingsForm(settings: IPodSyncSettings(deviceID: "preview"), tracks: LibraryTrack.previewTracks,
                     onDevice: [], freeBytes: 38_000_000_000, isSyncing: false, onSync: { _ in })
        .modelContainer(.preview)
}
