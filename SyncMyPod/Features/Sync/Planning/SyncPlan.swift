import Foundation

/// The tracks a sync would add, given what's selected and what's already on the iPod.
nonisolated struct SyncPlan: Equatable, Sendable {
    let requests: [IPodSyncRequest]
    let selectedCount: Int

    var alreadyOnDeviceCount: Int { selectedCount - requests.count }
    var byteCount: Int64 { requests.reduce(0) { $0 + Int64($1.draft.fileSize) } }

    @MainActor
    static func make(tracks: [LibraryTrack], mode: SyncMode, selectedAlbums: Set<String>,
                     onDevice: Set<IPodTrackMatchKey>) -> SyncPlan {
        let selected = mode == .allSongs ? tracks : tracks.filter { selectedAlbums.contains($0.syncAlbumKey) }
        let requests = selected.map(\.syncRequest).filter { !onDevice.contains($0.matchKey) }
        return SyncPlan(requests: requests, selectedCount: selected.count)
    }
}
