import Foundation

/// Works out which covers and lyric files belong beside the songs a sync puts on the player.
nonisolated struct PlayerSidecarPlanner {
    let config: AudioPlayerConfig
    let manifest: PlayerSyncManifest
    let presentSizes: [String: Int64]
    let sidecars: LibrarySidecars

    /// `destinations` maps each selected song's library path to its path on the player. With `pruning` off,
    /// as when adding a few songs, sidecars the manifest records for other songs are left alone.
    func plan(_ requests: [IPodSyncRequest], destinations: [String: String], pruning: Bool,
              into plan: inout PlayerSyncPlan) {
        let wanted = wantedSidecars(requests, destinations: destinations)
        plan.sidecarCopies = wanted.sorted { $0.key < $1.key }.compactMap { path, source in
            let isCurrent = manifest.sidecars[path] == source && presentSizes[path] != nil
            return isCurrent ? nil : PlayerSidecarCopy(source: source, destination: path)
        }
        plan.sidecarRemovals = pruning ? manifest.sidecars.keys.filter { wanted[$0] == nil }.sorted() : []
    }

    private func wantedSidecars(_ requests: [IPodSyncRequest], destinations: [String: String]) -> [String: SidecarFile] {
        var wanted: [String: SidecarFile] = [:]
        let sorted = requests.sorted { $0.sourcePath < $1.sourcePath }
        for request in sorted {
            guard let destination = destinations[request.sourcePath] else { continue }
            if config.copyLyricFiles, let lyric = sidecars.lyrics[request.sourcePath] {
                let path = (destination as NSString).deletingPathExtension + ".lrc"
                wanted[path] = wanted[path] ?? lyric
            }
            if config.copyCovers { addCovers(for: request, at: destination, to: &wanted) }
        }
        return wanted
    }

    /// The first library folder with covers, by path, supplies an album folder's covers, named in lowercase.
    private func addCovers(for request: IPodSyncRequest, at destination: String,
                           to wanted: inout [String: SidecarFile]) {
        let folder = (destination as NSString).deletingLastPathComponent
        let covers = sidecars.covers(besideSongAt: request.sourcePath)
        let alreadyCovered = LibrarySidecarFinder.coverNames.contains { wanted[AudioPlayerConfig.join(folder, $0)] != nil }
        guard !covers.isEmpty, !alreadyCovered else { return }
        for cover in covers {
            wanted[AudioPlayerConfig.join(folder, cover.fileName.lowercased())] = cover
        }
    }
}
