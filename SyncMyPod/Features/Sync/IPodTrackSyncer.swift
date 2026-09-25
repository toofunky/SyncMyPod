import Foundation

/// Adds and removes tracks and their cover art on a mounted iPod and updates its databases.
nonisolated struct IPodTrackSyncer {
    let volumeURL: URL
    var formats = ArtworkFormat.videoIPod
    /// Required by iPod classic firmware; `nil` for models that read an unsigned iTunesDB.
    var signer: Hash58?

    /// Skips requests already on the iPod. Cancelling stops copying but still saves the removals
    /// and the tracks already copied.
    @concurrent
    func sync(adding requests: [IPodSyncRequest], removing removals: Set<UInt64> = [],
              progress: @escaping @Sendable (IPodSyncProgress) async -> Void = { _ in }) async throws -> IPodSyncOutcome {
        let store = DatabaseFileStore.iTunesDB(onVolume: volumeURL)
        let files = IPodControlFiles(volumeURL: volumeURL)
        var editor = try openEditor(store)
        let mergedPlayCounts = files.playCounts().map { editor.mergePlayCounts($0) } ?? false
        let removedLocations = editor.removeTracks(databaseIDs: removals)
        let device = try ITunesDBParser(data: editor.serialized()).parse()
        let pending = newRequests(in: requests, notIn: device)
        var outcome = IPodSyncOutcome(skipped: requests.count - pending.count, removed: removedLocations.count)
        guard !pending.isEmpty || !removedLocations.isEmpty else { return outcome }
        try ensureFreeSpace(for: pending, freeing: files.totalSize(of: removedLocations))
        var artwork = try ArtworkSyncSession(volumeURL: volumeURL, formats: formats)
        artwork.removeImages(forTracks: removals)
        var copied: [URL] = []
        do {
            let batch = SyncBatch(requests: pending, albumTracks: Self.albumTracks(in: device), progress: progress)
            try await copyAndRecord(batch, into: &editor, artwork: &artwork, copied: &copied, outcome: &outcome)
            await progress(IPodSyncProgress(completed: outcome.addedCount, total: pending.count, currentTitle: nil))
            try artwork.save()
            try store.save(signer?.sign(editor.serialized()) ?? editor.serialized())
        } catch {
            copied.forEach { try? FileManager.default.removeItem(at: $0) }
            artwork.rollBack()
            throw error
        }
        files.cleanUp(removedLocations: removedLocations, playCountsMerged: mergedPlayCounts)
        artwork.compactIfWasteful()
        return outcome
    }

    /// Refuses to touch a signed database whose signature our key can't reproduce.
    private func openEditor(_ store: DatabaseFileStore) throws -> ITunesDBEditor {
        if let signer, let current = try? Data(contentsOf: store.fileURL), Hash58.isSigned(current),
           !signer.isValid(current) {
            throw IPodSyncError.signatureMismatch
        }
        return try ITunesDBEditor(root: store.loadRecords())
    }

    private func newRequests(in requests: [IPodSyncRequest], notIn device: ITunesDatabase) -> [IPodSyncRequest] {
        var seen = IPodTrackMatchKey.keys(in: device)
        return requests.filter { seen.insert($0.matchKey).inserted }
    }

    private static func albumTracks(in device: ITunesDatabase) -> [IPodAlbumKey: [UInt64]] {
        Dictionary(grouping: device.tracks, by: IPodAlbumKey.init).mapValues { $0.map(\.databaseID) }
    }

    private func copyAndRecord(_ batch: SyncBatch, into editor: inout ITunesDBEditor, artwork: inout ArtworkSyncSession,
                               copied: inout [URL], outcome: inout IPodSyncOutcome) async throws {
        let copier = IPodMusicFileCopier(volumeURL: volumeURL)
        for (index, request) in batch.requests.enumerated() {
            await batch.progress(IPodSyncProgress(completed: index, total: batch.requests.count,
                                                  currentTitle: request.draft.title))
            guard !Task.isCancelled else {
                outcome.wasCancelled = true
                return
            }
            let file = try copier.copy(request.sourceURL)
            copied.append(file.url)
            let albumTracks = batch.albumTracks[IPodAlbumKey(request.draft)] ?? []
            let prepared = try await artwork.prepare(coverFrom: request.sourceURL, albumTracks: albumTracks)
            var draft = request.draft
            draft.location = file.location
            draft.artwork = prepared?.trackArtwork
            let databaseID = editor.addTrack(draft)
            if let prepared { artwork.attach(prepared, toTrack: databaseID) }
            outcome.addedDatabaseIDs[request.sourceURL.path(percentEncoded: false)] = databaseID
        }
    }

    private func ensureFreeSpace(for requests: [IPodSyncRequest], freeing freedBytes: Int64) throws {
        let artworkBytes = formats.reduce(0) { $0 + $1.byteCount }
        let required = requests.reduce(Int64(0)) { $0 + Int64($1.draft.fileSize + artworkBytes) }
        let values = try volumeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        let available = Int64(values.volumeAvailableCapacity ?? 0) + freedBytes
        guard required < available else {
            throw IPodSyncError.insufficientSpace(required: required, available: available)
        }
    }
}
