import Foundation

/// Adds, updates and removes tracks and their cover art on a mounted iPod and updates its databases.
nonisolated struct IPodTrackSyncer {
    let volumeURL: URL
    var formats = ArtworkFormat.videoIPod
    /// Required by iPod classic firmware; `nil` for models that read an unsigned iTunesDB.
    var signer: Hash58?

    /// Adds requests that aren't on the iPod and updates those whose file changed since the manifest recorded
    /// it; the rest are skipped. Cancelling stops copying but still saves the removals and the songs already copied.
    @concurrent
    func sync(adding requests: [IPodSyncRequest], removing removals: Set<UInt64> = [],
              progress: @escaping @Sendable (IPodSyncProgress) async -> Void = { _ in }) async throws -> IPodSyncOutcome {
        let store = DatabaseFileStore.iTunesDB(onVolume: volumeURL)
        let files = IPodControlFiles(volumeURL: volumeURL)
        var editor = try openEditor(store)
        let mergedPlayCounts = files.playCounts().map { editor.mergePlayCounts($0) } ?? false
        let removedLocations = editor.removeTracks(databaseIDs: removals)
        let device = try ITunesDBParser(data: editor.serialized()).parse()
        let manifest = files.manifest().valid(for: Set(device.tracks.map(\.databaseID)))
        let batch = Self.batch(for: requests, device: device, manifest: manifest, progress: progress)
        let outcome = IPodSyncOutcome(skipped: requests.count - batch.items.count, removed: removedLocations.count)
        guard !batch.items.isEmpty || !removedLocations.isEmpty else { return outcome }
        try ensureFreeSpace(for: batch.items, freeing: files.totalSize(of: removedLocations))
        var artwork = try ArtworkSyncSession(volumeURL: volumeURL, formats: formats)
        artwork.removeImages(forTracks: removals)
        var writer = IPodBatchWriter(editor: editor, artwork: artwork, outcome: outcome,
                                     copier: IPodMusicFileCopier(volumeURL: volumeURL), albumTracks: batch.albumTracks)
        try await commit(batch, with: &writer, store: store)
        try? files.save(manifest.recording(batch.items.map(\.request), as: writer.outcome.syncedDatabaseIDs))
        files.cleanUp(removedLocations: removedLocations, replacedLocations: writer.replacedLocations,
                      playCountsMerged: mergedPlayCounts)
        writer.artwork.compactIfWasteful()
        return writer.outcome
    }

    /// Copies the batch and saves both databases, or deletes the copies and restores the ArtworkDB.
    private func commit(_ batch: SyncBatch, with writer: inout IPodBatchWriter, store: DatabaseFileStore) async throws {
        do {
            try await write(batch, with: &writer)
            let done = writer.outcome.addedCount + writer.outcome.updatedCount
            await batch.progress(IPodSyncProgress(completed: done, total: batch.items.count, currentTitle: nil))
            try writer.artwork.save()
            try store.save(signer?.sign(writer.editor.serialized()) ?? writer.editor.serialized())
        } catch {
            writer.copied.forEach { try? FileManager.default.removeItem(at: $0) }
            writer.artwork.rollBack()
            throw error
        }
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
    private static func batch(for requests: [IPodSyncRequest], device: ITunesDatabase, manifest: SyncManifest,
                              progress: @escaping @Sendable (IPodSyncProgress) async -> Void) -> SyncBatch {
        let plan = SyncPlanner(manifest: manifest, onDevice: device.tracks).plan(selected: requests, unselected: [])
        var updatedIDs: Set<UInt64> = []
        var seenKeys: Set<IPodTrackMatchKey> = []
        let updates = plan.updates.filter { updatedIDs.insert($0.databaseID).inserted }.map(SyncBatchItem.update)
        let additions = plan.requests.filter { seenKeys.insert($0.matchKey).inserted }.map(SyncBatchItem.add)
        return SyncBatch(items: updates + additions, albumTracks: albumTracks(in: device), progress: progress)
    }

    /// Refuses to touch a signed database whose signature our key can't reproduce.
    private func openEditor(_ store: DatabaseFileStore) throws -> ITunesDBEditor {
        if let signer, let current = try? Data(contentsOf: store.fileURL), Hash58.isSigned(current),
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
