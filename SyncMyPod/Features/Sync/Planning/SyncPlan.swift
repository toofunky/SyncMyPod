import Foundation

/// What a sync would change: tracks to add or update, and library tracks on the iPod that are no longer
/// selected, whose file is gone, or that duplicate a library song's copy.
nonisolated struct SyncPlan: Equatable, Sendable {
    let requests: [IPodSyncRequest]
    let updates: [IPodTrackUpdate]
    let removals: [ITunesTrack]
    let selectedCount: Int

    init(requests: [IPodSyncRequest], updates: [IPodTrackUpdate] = [], removals: [ITunesTrack],
         selectedCount: Int) {
        self.requests = requests
        self.updates = updates
        self.removals = removals
        self.selectedCount = selectedCount
    }

    var isEmpty: Bool { requests.isEmpty && updates.isEmpty && removals.isEmpty }
    var alreadyOnDeviceCount: Int { selectedCount - requests.count - updates.count }
    /// What the syncer is handed: it works out again which of these are additions and which are updates.
    var syncRequests: [IPodSyncRequest] { requests + updates.map(\.request) }
    var byteCount: Int64 { requests.reduce(0) { $0 + Int64($1.draft.fileSize) } }
    var updatedByteCount: Int64 { updates.reduce(0) { $0 + Int64($1.request.draft.fileSize) } }
    var removedByteCount: Int64 { removals.reduce(0) { $0 + Int64($1.fileSize) } }
    var removalIDs: Set<UInt64> { Set(removals.map(\.databaseID)) }

    @MainActor
    static func make(tracks: [LibraryTrack], mode: SyncMode, selectedAlbums: Set<String>,
                     onDevice: [ITunesTrack], manifest: SyncManifest = SyncManifest(),
                     strayDatabaseIDs: Set<UInt64> = []) -> SyncPlan {
        let isSelected = { (track: LibraryTrack) in mode == .allSongs || selectedAlbums.contains(track.syncAlbumKey) }
        return SyncPlanner(manifest: manifest, onDevice: onDevice, strayDatabaseIDs: strayDatabaseIDs)
            .plan(selected: tracks.filter(isSelected).map(\.syncRequest),
                  unselected: tracks.filter { !isSelected($0) }.map(\.syncRequest))
    }
}
