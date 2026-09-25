import Foundation

/// Which library file each iPod track came from, kept on the iPod beside its iTunesDB.
nonisolated struct SyncManifest: Codable, Equatable, Sendable {
    /// Keyed by the library file's path.
    private(set) var entries: [String: SyncManifestEntry] = [:]

    var claimedDatabaseIDs: Set<UInt64> { Set(entries.values.map(\.databaseID)) }

    func entry(for request: IPodSyncRequest) -> SyncManifestEntry? {
        entries[request.sourcePath]
    }

    /// Drops entries whose track is gone, e.g. removed by another app.
    func valid(for databaseIDs: Set<UInt64>) -> SyncManifest {
        SyncManifest(entries: entries.filter { databaseIDs.contains($0.value.databaseID) })
    }

    /// Adds entries for tracks just copied to the iPod, keyed like `IPodSyncOutcome.addedDatabaseIDs`.
    func recording(_ requests: [IPodSyncRequest], as databaseIDs: [String: UInt64]) -> SyncManifest {
        var updated = self
        for request in requests {
            guard let source = request.source, let databaseID = databaseIDs[request.sourcePath] else { continue }
            updated.entries[request.sourcePath] = SyncManifestEntry(databaseID: databaseID, source: source)
        }
        return updated
    }

    /// Links the file to a track whose file state is unknown, so the next sync rewrites it.
    mutating func link(_ request: IPodSyncRequest, to databaseID: UInt64) {
        entries[request.sourcePath] = SyncManifestEntry(databaseID: databaseID, source: nil)
    }

    /// Moves entries whose file is `missing` to library files without an entry whose tags match their track,
    /// one each, so a renamed or moved file keeps its iPod copy. Returns whether anything moved.
    mutating func relink(_ requests: [IPodSyncRequest], onDevice: [ITunesTrack], missing: Set<String>) -> Bool {
        let keys = Dictionary(onDevice.map { ($0.databaseID, IPodTrackMatchKey($0)) },
                              uniquingKeysWith: { first, _ in first })
        var movable: [IPodTrackMatchKey: [String]] = [:]
        for path in missing.sorted() {
            guard let key = entries[path].flatMap({ keys[$0.databaseID] }) else { continue }
            movable[key, default: []].append(path)
        }
        var moved = false
        for request in requests where entry(for: request) == nil {
            guard let oldPath = movable[request.matchKey]?.popLast() else { continue }
            entries[request.sourcePath] = entries.removeValue(forKey: oldPath)
            moved = true
        }
        return moved
    }

    /// Links library files without an entry to unclaimed iPod tracks with the same tags, one each.
    /// Returns whether anything was added.
    mutating func adopt(_ requests: [IPodSyncRequest], onDevice: [ITunesTrack]) -> Bool {
        let claimed = claimedDatabaseIDs
        var unclaimed = Dictionary(grouping: onDevice.filter { !claimed.contains($0.databaseID) },
                                   by: IPodTrackMatchKey.init)
        var adopted = false
        for request in requests where entry(for: request) == nil {
            guard let source = request.source, let track = unclaimed[request.matchKey]?.popLast() else { continue }
            entries[request.sourcePath] = SyncManifestEntry(databaseID: track.databaseID, source: source)
            adopted = true
        }
        return adopted
    }
}
