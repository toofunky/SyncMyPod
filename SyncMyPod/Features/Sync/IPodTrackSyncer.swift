import Foundation

/// Copies tracks and their cover art onto a mounted iPod and records them in its databases.
nonisolated struct IPodTrackSyncer {
    let volumeURL: URL
    var formats = ArtworkFormat.videoIPod

    /// Skips tracks already on the iPod. Cancelling stops copying but still saves the tracks already copied.
    @concurrent
    func add(_ requests: [IPodSyncRequest],
             progress: @escaping @Sendable (IPodSyncProgress) async -> Void = { _ in }) async throws -> IPodSyncOutcome {
        let store = DatabaseFileStore.iTunesDB(onVolume: volumeURL)
        var editor = try ITunesDBEditor(root: store.loadRecords())
        let pending = try newRequests(in: requests, notIn: editor)
        var outcome = IPodSyncOutcome(skipped: requests.count - pending.count)
        guard !pending.isEmpty else { return outcome }
        try ensureFreeSpace(for: pending)
        var artwork = try ArtworkSyncSession(volumeURL: volumeURL, formats: formats)
        var copied: [URL] = []
        do {
            try await copyAndRecord(pending, into: &editor, artwork: &artwork, copied: &copied,
                                    outcome: &outcome, progress: progress)
            await progress(IPodSyncProgress(completed: outcome.addedCount, total: pending.count, currentTitle: nil))
            try artwork.save()
            try store.save(editor.serialized())
            return outcome
        } catch {
            copied.forEach { try? FileManager.default.removeItem(at: $0) }
            artwork.rollBack()
            throw error
        }
    }

    private func newRequests(in requests: [IPodSyncRequest], notIn editor: ITunesDBEditor) throws -> [IPodSyncRequest] {
        var seen = IPodTrackMatchKey.keys(in: try ITunesDBParser(data: editor.serialized()).parse())
        return requests.filter { seen.insert($0.matchKey).inserted }
    }

    private func copyAndRecord(_ requests: [IPodSyncRequest], into editor: inout ITunesDBEditor,
                               artwork: inout ArtworkSyncSession, copied: inout [URL], outcome: inout IPodSyncOutcome,
                               progress: @Sendable (IPodSyncProgress) async -> Void) async throws {
        let copier = IPodMusicFileCopier(volumeURL: volumeURL)
        for (index, request) in requests.enumerated() {
            await progress(IPodSyncProgress(completed: index, total: requests.count, currentTitle: request.draft.title))
            guard !Task.isCancelled else {
                outcome.wasCancelled = true
                return
            }
            let file = try copier.copy(request.sourceURL)
            copied.append(file.url)
            let prepared = try await artwork.prepare(coverFrom: request.sourceURL)
            var draft = request.draft
            draft.location = file.location
            draft.artwork = prepared?.trackArtwork
            let databaseID = editor.addTrack(draft)
            if let prepared { artwork.attach(prepared, toTrack: databaseID) }
            outcome.addedDatabaseIDs[request.sourceURL.path(percentEncoded: false)] = databaseID
        }
    }

    private func ensureFreeSpace(for requests: [IPodSyncRequest]) throws {
        let artworkBytes = formats.reduce(0) { $0 + $1.byteCount }
        let required = requests.reduce(Int64(0)) { $0 + Int64($1.draft.fileSize + artworkBytes) }
        let values = try volumeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        let available = Int64(values.volumeAvailableCapacity ?? 0)
        guard required < available else {
            throw IPodSyncError.insufficientSpace(required: required, available: available)
        }
    }
}
