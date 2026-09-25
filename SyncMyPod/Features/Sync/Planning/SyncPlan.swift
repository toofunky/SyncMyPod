import Foundation

/// What a sync would change: tracks to add, and library tracks on the iPod that are no longer selected.
/// Songs the library doesn't know about are never removed.
nonisolated struct SyncPlan: Equatable, Sendable {
    let requests: [IPodSyncRequest]
    let removals: [ITunesTrack]
    let selectedCount: Int

    var isEmpty: Bool { requests.isEmpty && removals.isEmpty }
    var alreadyOnDeviceCount: Int { selectedCount - requests.count }
    var byteCount: Int64 { requests.reduce(0) { $0 + Int64($1.draft.fileSize) } }
    var removedByteCount: Int64 { removals.reduce(0) { $0 + Int64($1.fileSize) } }
    var removalIDs: Set<UInt64> { Set(removals.map(\.databaseID)) }

    @MainActor
    static func make(tracks: [LibraryTrack], mode: SyncMode, selectedAlbums: Set<String>,
                     onDevice: [ITunesTrack]) -> SyncPlan {
        let deviceTracks = Dictionary(grouping: onDevice, by: IPodTrackMatchKey.init)
        let isSelected = { (track: LibraryTrack) in mode == .allSongs || selectedAlbums.contains(track.syncAlbumKey) }
        let selected = tracks.filter(isSelected).map(\.syncRequest)
        let unselectedKeys = Set(tracks.filter { !isSelected($0) }.map(\.syncRequest.matchKey))
            .subtracting(selected.map(\.matchKey))
        let removals = unselectedKeys.flatMap { deviceTracks[$0] ?? [] }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        return SyncPlan(requests: selected.filter { deviceTracks[$0.matchKey] == nil },
                        removals: removals, selectedCount: selected.count)
    }
}
