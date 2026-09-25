import Foundation

/// Copies tracks and their cover art onto a mounted iPod and records them in its databases.
nonisolated struct IPodTrackSyncer {
    let volumeURL: URL
    var formats = ArtworkFormat.videoIPod

    /// Returns the new database ID for each added track, keyed by source path.
    @concurrent
    func add(_ requests: [IPodSyncRequest]) async throws -> [String: UInt64] {
        let store = DatabaseFileStore.iTunesDB(onVolume: volumeURL)
        var editor = try ITunesDBEditor(root: store.loadRecords())
        let pending = requests.filter { request in
            request.existingDatabaseID.map { !editor.containsTrack(databaseID: $0) } ?? true
        }
        guard !pending.isEmpty else { return [:] }
        try ensureFreeSpace(for: pending)
        var artwork = try ArtworkSyncSession(volumeURL: volumeURL, formats: formats)
        var copied: [URL] = []
        do {
            let added = try await copyAndRecord(pending, into: &editor, artwork: &artwork, copied: &copied)
            try artwork.save()
            try store.save(editor.serialized())
            return added
        } catch {
            copied.forEach { try? FileManager.default.removeItem(at: $0) }
            artwork.rollBack()
            throw error
        }
    }

    private func copyAndRecord(_ requests: [IPodSyncRequest], into editor: inout ITunesDBEditor,
                               artwork: inout ArtworkSyncSession, copied: inout [URL]) async throws -> [String: UInt64] {
        let copier = IPodMusicFileCopier(volumeURL: volumeURL)
        var added: [String: UInt64] = [:]
        for request in requests {
            try Task.checkCancellation()
            let file = try copier.copy(request.sourceURL)
            copied.append(file.url)
            let prepared = try await artwork.prepare(coverFrom: request.sourceURL)
            var draft = request.draft
            draft.location = file.location
            draft.artwork = prepared?.trackArtwork
            let databaseID = editor.addTrack(draft)
            if let prepared { artwork.attach(prepared, toTrack: databaseID) }
            added[request.sourceURL.path(percentEncoded: false)] = databaseID
        }
        return added
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
