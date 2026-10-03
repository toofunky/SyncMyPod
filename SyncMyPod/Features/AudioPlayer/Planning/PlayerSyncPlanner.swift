import Foundation

/// Works out which files to copy, move and delete on a player, touching only copies its manifest records.
nonisolated struct PlayerSyncPlanner {
    let config: AudioPlayerConfig
    let manifest: PlayerSyncManifest
    /// Sizes of the manifest's files that are on the player, keyed by path.
    var presentSizes: [String: Int64] = [:]
    /// Library files known to be deleted, whose copies are removed whatever is selected.
    var missingSources: Set<String> = []
    /// The playlist folder's `.m3u8` files, keyed by path, so unchanged ones aren't counted or rewritten.
    var existingPlaylists: [String: String] = [:]
    /// Covers and lyric files beside the library's songs, copied when the config asks for them.
    var sidecars = LibrarySidecars()

    private var builder: PlayerPathBuilder { PlayerPathBuilder(config: config) }

    /// `nil` `playlists` leaves the player's playlists alone, and leaves covers and lyrics copied for songs
    /// that aren't in `selected`, as when adding a few songs.
    func plan(selected: [IPodSyncRequest], unselected: [IPodSyncRequest] = [],
              playlists: [IPodPlaylistRequest]?) -> PlayerSyncPlan {
        let selected = Self.unique(selected)
        var plan = PlayerSyncPlan(selectedCount: selected.count)
        plan.removals = removals(unselected, keeping: Set(selected.map(\.sourcePath)))
        let destinations = destinations(for: selected, removing: Set(plan.removals.map(\.sourcePath)))
        for request in selected {
            guard let destination = destinations[request.sourcePath] else { continue }
            classify(request, destination: destination, into: &plan)
        }
        if let playlists { add(playlists, destinations: destinations, to: &plan) }
        PlayerSidecarPlanner(config: config, manifest: manifest, presentSizes: presentSizes, sidecars: sidecars)
            .plan(selected, destinations: destinations, pruning: playlists != nil, into: &plan)
        return plan
    }

    private func classify(_ request: IPodSyncRequest, destination: String, into plan: inout PlayerSyncPlan) {
        guard let entry = manifest.entries[request.sourcePath], presentSizes[entry.path] != nil else {
            plan.copies.append(PlayerFileCopy(request: request, destination: destination))
            return
        }
        if let source = request.source, source != entry.source {
            let replacing = entry.path == destination ? nil : entry.path
            plan.updates.append(PlayerFileCopy(request: request, destination: destination, replacing: replacing))
        } else if entry.path != destination {
            plan.moves.append(PlayerFileMove(sourcePath: request.sourcePath, from: entry.path, to: destination))
        }
    }

    private func removals(_ unselected: [IPodSyncRequest], keeping kept: Set<String>) -> [PlayerFileRemoval] {
        let removed = Set(unselected.map(\.sourcePath)).union(missingSources).subtracting(kept)
        return removed.compactMap { sourcePath in
            manifest.entries[sourcePath].map {
                PlayerFileRemoval(sourcePath: sourcePath, path: $0.path, byteCount: presentSizes[$0.path] ?? 0)
            }
        }
        .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    /// One path per file, compared case-insensitively as FAT and exFAT do, avoiding copies the sync keeps.
    private func destinations(for requests: [IPodSyncRequest], removing removed: Set<String>) -> [String: String] {
        let moving = Set(requests.map(\.sourcePath)).union(removed)
        var taken = Set(manifest.entries.filter { !moving.contains($0.key) }.map { $0.value.path.lowercased() })
        var destinations: [String: String] = [:]
        for request in requests.sorted(by: { $0.sourcePath < $1.sourcePath }) {
            destinations[request.sourcePath] = Self.claim(builder.path(for: request), in: &taken)
        }
        return destinations
    }

    private func add(_ playlists: [IPodPlaylistRequest], destinations: [String: String],
                     to plan: inout PlayerSyncPlan) {
        let others = Set(existingPlaylists.keys).subtracting(manifest.playlistPaths)
        var taken = Set(others.map { $0.lowercased() })
        let files = playlists.map { playlist in
            let name = PlayerFileNamer.safeComponent(playlist.name, fallback: "Playlist") + ".m3u8"
            let path = Self.claim(AudioPlayerConfig.join(config.playlistPath, name), in: &taken)
            let entries = playlist.tracks.compactMap { track in destinations[track.sourcePath].map { (track.draft, $0) } }
            return PlayerPlaylistFile(path: path, contents: M3U8Playlist.contents(entries, inFolder: config.playlistPath))
        }
        plan.playlists = files
        plan.stalePlaylistPaths = manifest.playlistPaths.subtracting(files.map(\.path)).sorted()
        plan.playlistChangeCount = files.filter { existingPlaylists[$0.path] != $0.contents }.count
            + plan.stalePlaylistPaths.count
    }

    private static func claim(_ wanted: String, in taken: inout Set<String>) -> String {
        var path = wanted
        var copy = 2
        while taken.contains(path.lowercased()) {
            path = PlayerFileNamer.numbered(wanted, copy: copy)
            copy += 1
        }
        taken.insert(path.lowercased())
        return path
    }

    private static func unique(_ requests: [IPodSyncRequest]) -> [IPodSyncRequest] {
        var seen: Set<String> = []
        return requests.filter { seen.insert($0.sourcePath).inserted }
    }
}
