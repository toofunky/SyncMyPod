import Foundation

/// Matches library files to iPod tracks through the manifest first, then by tags for files it doesn't know.
nonisolated struct SyncPlanner {
    private let manifest: SyncManifest
    private let strayDatabaseIDs: Set<UInt64>
    private let deviceByID: [UInt64: ITunesTrack]
    private let deviceKeys: Set<IPodTrackMatchKey>
    /// Only tracks no manifest entry claims, so removing an untracked file can't take another file's copy.
    private let unclaimedByKey: [IPodTrackMatchKey: [ITunesTrack]]

    /// `strayDatabaseIDs` are removed whatever is selected: see `LoadedSyncManifest`.
    init(manifest: SyncManifest, onDevice: [ITunesTrack], strayDatabaseIDs: Set<UInt64> = []) {
        let valid = manifest.valid(for: Set(onDevice.map(\.databaseID)))
        let claimed = valid.claimedDatabaseIDs
        self.manifest = valid
        self.strayDatabaseIDs = strayDatabaseIDs
        deviceByID = Dictionary(onDevice.map { ($0.databaseID, $0) }, uniquingKeysWith: { first, _ in first })
        deviceKeys = Set(onDevice.map(IPodTrackMatchKey.init))
        unclaimedByKey = Dictionary(grouping: onDevice.filter { !claimed.contains($0.databaseID) },
                                    by: IPodTrackMatchKey.init)
    }

    func plan(selected: [IPodSyncRequest], unselected: [IPodSyncRequest]) -> SyncPlan {
        var requests: [IPodSyncRequest] = []
        var updates: [IPodTrackUpdate] = []
        for request in selected {
            if let entry = manifest.entry(for: request) {
                if let update = update(request, entry) { updates.append(update) }
            } else if !deviceKeys.contains(request.matchKey) {
                requests.append(request)
            }
        }
        return SyncPlan(requests: requests, updates: updates,
                        removals: removals(unselected, keeping: selected), selectedCount: selected.count)
    }

    /// `nil` when the file is unchanged, or hasn't been scanned closely enough to tell. An entry without a
    /// source always updates, redrawing the cover since what's on the iPod is unknown.
    private func update(_ request: IPodSyncRequest, _ entry: SyncManifestEntry) -> IPodTrackUpdate? {
        guard let source = request.source, source != entry.source else { return nil }
        let artworkChanged = entry.source.map { $0.artworkFingerprint != source.artworkFingerprint } ?? true
        return IPodTrackUpdate(request: request, databaseID: entry.databaseID, artworkChanged: artworkChanged)
    }

    private func removals(_ unselected: [IPodSyncRequest], keeping selected: [IPodSyncRequest]) -> [ITunesTrack] {
        let keptIDs = Set(selected.compactMap { manifest.entry(for: $0)?.databaseID })
        let keptKeys = Set(selected.map(\.matchKey))
        var removedIDs = strayDatabaseIDs
        for request in unselected {
            if let entry = manifest.entry(for: request) {
                removedIDs.insert(entry.databaseID)
            } else if !keptKeys.contains(request.matchKey) {
                removedIDs.formUnion(unclaimedByKey[request.matchKey]?.map(\.databaseID) ?? [])
            }
        }
        return removedIDs.subtracting(keptIDs).compactMap { deviceByID[$0] }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}
