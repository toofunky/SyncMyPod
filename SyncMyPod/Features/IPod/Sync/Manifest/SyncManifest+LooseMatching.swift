import Foundation

nonisolated extension SyncManifest {
    /// Links library files that still have no entry, and no iPod track with their tags, to the one unclaimed track
    /// that loosely matches. The entry has no source, so the next sync rewrites the track from the file.
    mutating func adoptLoosely(_ requests: [IPodSyncRequest], onDevice: [ITunesTrack]) -> Bool {
        let deviceKeys = Set(onDevice.map(IPodTrackMatchKey.init))
        let claimed = claimedDatabaseIDs
        var unclaimed = onDevice.filter { !claimed.contains($0.databaseID) }
        var adopted = false
        for request in requests where request.source != nil && entry(for: request) == nil
            && !deviceKeys.contains(request.matchKey) {
            let candidates = unclaimed.filter { LooseTrackMatch.matches(request, $0) }
            guard candidates.count == 1, let track = candidates.first else { continue }
            link(request, to: track.databaseID)
            unclaimed.removeAll { $0.databaseID == track.databaseID }
            adopted = true
        }
        return adopted
    }

    /// Unclaimed iPod tracks that no library file's tags match, but that loosely match a file already linked to
    /// another track: copies left behind when a file was edited before it had an entry.
    func duplicates(among onDevice: [ITunesTrack], of requests: [IPodSyncRequest]) -> Set<UInt64> {
        let claimed = claimedDatabaseIDs
        let libraryKeys = Set(requests.map(\.matchKey))
        let linked = requests.filter { entry(for: $0) != nil }
        return Set(onDevice.filter { track in
            !claimed.contains(track.databaseID) && !libraryKeys.contains(IPodTrackMatchKey(track))
                && linked.contains { LooseTrackMatch.matches($0, track) }
        }.map(\.databaseID))
    }
}
