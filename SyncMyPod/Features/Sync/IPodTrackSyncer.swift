import Foundation

/// Adds, updates and removes tracks and their cover art on a mounted iPod and updates its databases.
nonisolated struct IPodTrackSyncer {
    let volumeURL: URL
    var formats = ArtworkFormat.videoIPod
    /// Required by iPod classic and nano 6G/7G firmware; `nil` for models that read an unsigned iTunesDB.
    var signer: (any IPodDatabaseSigner)?
    /// Set for the nano 6G/7G, which read a compressed iTunesCDB and an SQLite library generated from it.
    var nanoLibrary: NanoLibraryWriter?

    private var store: DatabaseFileStore {
        nanoLibrary == nil ? .iTunesDB(onVolume: volumeURL) : .iTunesCDB(onVolume: volumeURL)
    }

    /// Adds requests that aren't on the iPod and updates those whose file changed since the manifest recorded
    /// it; the rest are skipped. Cancelling stops copying but still saves the removals and the songs already copied.
    /// Non-`nil` `playlists` replace the playlists earlier syncs wrote.
    @concurrent
    func sync(adding requests: [IPodSyncRequest], removing removals: Set<UInt64> = [],
              playlists: [IPodPlaylistRequest]? = nil,
              progress: @escaping @Sendable (IPodSyncProgress) async -> Void = { _ in }) async throws -> IPodSyncOutcome {
        let files = IPodControlFiles(volumeURL: volumeURL)
        var editor = try openEditor(store)
        let mergedPlayCounts = mergePlayStatistics(into: &editor, files: files)
        let removedLocations = editor.removeTracks(databaseIDs: removals)
        let device = try ITunesDBParser(data: editor.serialized()).parse()
        let manifest = files.manifest().valid(for: Set(device.tracks.map(\.databaseID)))
        let batch = Self.batch(for: requests, playlists: playlists, device: device, manifest: manifest,
                               progress: progress)
        let outcome = IPodSyncOutcome(skipped: requests.count - batch.items.count, removed: removedLocations.count)
        guard !batch.isEmpty || !removedLocations.isEmpty else { return outcome }
        try ensureFreeSpace(for: batch.items, freeing: files.totalSize(of: removedLocations))
        var artwork = try ArtworkSyncSession(volumeURL: volumeURL, formats: formats)
        artwork.removeImages(forTracks: removals)
        var writer = IPodBatchWriter(editor: editor, artwork: artwork, outcome: outcome,
                                     copier: IPodMusicFileCopier(volumeURL: volumeURL), albumTracks: batch.albumTracks)
        try await commit(batch, with: &writer, store: store)
        try? files.save(batch.manifest(after: writer.outcome))
        files.cleanUp(removedLocations: removedLocations, replacedLocations: writer.replacedLocations,
                      playCountsMerged: mergedPlayCounts)
        writer.artwork.compactIfWasteful()
        return writer.outcome
    }

    /// Classics report plays since the last sync in Play Counts. The nano reports the same plays there, but its
    /// Dynamic.itdb holds running totals, which are taken instead; its Play Counts file is then discarded.
    private func mergePlayStatistics(into editor: inout ITunesDBEditor, files: IPodControlFiles) -> Bool {
        guard nanoLibrary != nil else { return files.playCounts().map { editor.mergePlayCounts($0) } ?? false }
        let dynamic = NanoLibraryInstaller(volumeURL: volumeURL).folderURL.appending(path: NanoLibraryFile.dynamic.fileName)
        _ = editor.applyNanoStatistics(NanoPlayStatistics.load(from: dynamic))
        return true
    }

    /// Copies the batch and saves both databases, or deletes the copies and restores the ArtworkDB.
    private func commit(_ batch: SyncBatch, with writer: inout IPodBatchWriter, store: DatabaseFileStore) async throws {
        do {
            try await write(batch, with: &writer)
            if let playlists = batch.playlists { writer.writePlaylists(playlists, resolver: batch.resolver) }
            let done = writer.outcome.addedCount + writer.outcome.updatedCount
            await batch.progress(IPodSyncProgress(completed: done, total: batch.items.count, currentTitle: nil))
            try writer.artwork.save()
            try saveDatabase(writer.editor.serialized(), to: store)
        } catch {
            writer.copied.forEach { try? FileManager.default.removeItem(at: $0) }
            writer.artwork.rollBack()
            throw error
        }
    }

    /// For the nano, the SQLite library is generated before the iTunesCDB is replaced and installed after it;
    /// if installing fails, the previous iTunesCDB is put back so the two never disagree.
    private func saveDatabase(_ database: Data, to store: DatabaseFileStore) throws {
        guard let nanoLibrary else { return try store.save(encoded(database)) }
        let staged = URL.temporaryDirectory.appending(path: "SyncMyPod-itlp-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: staged) }
        let installer = NanoLibraryInstaller(volumeURL: volumeURL)
        let previous = FileManager.default.fileExists(atPath: installer.folderURL.path(percentEncoded: false))
        try nanoLibrary.write(NanoLibrarySnapshot(database: database), to: staged,
                              carryingOverFrom: previous ? installer.folderURL : nil)
        let original = store.exists ? try Data(contentsOf: store.fileURL) : nil
        try store.save(encoded(database))
        do {
            try installer.install(from: staged)
        } catch {
            try? store.restore(original)
            throw error
        }
    }

    private func encoded(_ database: Data) throws -> Data {
        let stored = nanoLibrary == nil ? database : try ITunesCDB.compress(database)
        return try signer?.sign(stored) ?? stored
    }

    private func write(_ batch: SyncBatch, with writer: inout IPodBatchWriter) async throws {
        for (index, item) in batch.items.enumerated() {
            await batch.progress(IPodSyncProgress(completed: index, total: batch.items.count,
                                                  currentTitle: item.request.draft.title))
            guard !Task.isCancelled else {
                writer.outcome.wasCancelled = true
                return
            }
            try await writer.write(item)
        }
    }

    /// Updates first, then additions, each file and each iPod track at most once.
    private static func batch(for requests: [IPodSyncRequest], playlists: [IPodPlaylistRequest]?,
                              device: ITunesDatabase, manifest: SyncManifest,
                              progress: @escaping @Sendable (IPodSyncProgress) async -> Void) -> SyncBatch {
        let plan = SyncPlanner(manifest: manifest, onDevice: device.tracks).plan(selected: requests, unselected: [])
        var updatedIDs: Set<UInt64> = []
        var seenKeys: Set<IPodTrackMatchKey> = []
        let updates = plan.updates.filter { updatedIDs.insert($0.databaseID).inserted }.map(SyncBatchItem.update)
        let additions = plan.requests.filter { seenKeys.insert($0.matchKey).inserted }.map(SyncBatchItem.add)
        return SyncBatch(items: updates + additions, albumTracks: albumTracks(in: device), playlists: playlists,
                         resolver: PlaylistTrackResolver(manifest: manifest, onDevice: device.tracks),
                         progress: progress)
    }

    /// Refuses to touch a signed database whose signature our key can't reproduce.
    private func openEditor(_ store: DatabaseFileStore) throws -> ITunesDBEditor {
        if let signer, let current = try? Data(contentsOf: store.fileURL), type(of: signer).isSigned(current),
           !signer.isValid(current) {
            throw IPodSyncError.signatureMismatch
        }
        return try ITunesDBEditor(root: store.loadRecords())
    }

    private static func albumTracks(in device: ITunesDatabase) -> [IPodAlbumKey: [UInt64]] {
        Dictionary(grouping: device.tracks, by: IPodAlbumKey.init).mapValues { $0.map(\.databaseID) }
    }

    /// Replaced files are only deleted after copying, so updates need room for their whole new file.
    private func ensureFreeSpace(for items: [SyncBatchItem], freeing freedBytes: Int64) throws {
        let artworkBytes = formats.reduce(0) { $0 + $1.byteCount }
        let required = items.reduce(Int64(0)) { $0 + Int64($1.request.draft.fileSize + artworkBytes) }
        let values = try volumeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        let available = Int64(values.volumeAvailableCapacity ?? 0) + freedBytes
        guard required < available else {
            throw IPodSyncError.insufficientSpace(required: required, available: available)
        }
    }
}
