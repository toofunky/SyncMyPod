import Foundation

nonisolated extension IPodControlFiles {
    /// An empty manifest when there's none or it can't be read, so matching falls back to tags.
    func manifest() -> SyncManifest {
        guard let data = try? Data(contentsOf: manifestURL) else { return SyncManifest() }
        return (try? PropertyListDecoder().decode(SyncManifest.self, from: data)) ?? SyncManifest()
    }

    /// Binary so modification dates round-trip exactly.
    func save(_ manifest: SyncManifest) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        try encoder.encode(manifest).write(to: manifestURL, options: .atomic)
    }

    /// The manifest for `onDevice` after relinking renamed files and adopting library files already on the iPod,
    /// saved if that changed it. Pass `libraryFolder` to find entries whose file was deleted.
    @concurrent
    func manifest(adopting requests: [IPodSyncRequest], onDevice: [ITunesTrack],
                  libraryFolder: String?) async -> LoadedSyncManifest {
        var manifest = manifest().valid(for: Set(onDevice.map(\.databaseID)))
        let libraryPaths = Set(requests.map(\.sourcePath))
        let missing = libraryFolder.map {
            MissingSourceFinder(folderPath: $0).missing(manifest.entries.keys, notIn: libraryPaths)
        } ?? []
        let relinked = manifest.relink(requests, onDevice: onDevice, missing: missing)
        let adopted = manifest.adopt(requests, onDevice: onDevice)
        let adoptedLoosely = manifest.adoptLoosely(requests, onDevice: onDevice)
        if relinked || adopted || adoptedLoosely { try? save(manifest) }
        let orphaned = missing.compactMap { manifest.entries[$0]?.databaseID }
        let duplicates = manifest.duplicates(among: onDevice, of: requests)
        return LoadedSyncManifest(manifest: manifest, strayDatabaseIDs: duplicates.union(orphaned))
    }
}
