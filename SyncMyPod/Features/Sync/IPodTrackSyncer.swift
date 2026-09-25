import Foundation

/// Copies tracks onto a mounted iPod and records them in its iTunesDB.
nonisolated struct IPodTrackSyncer {
    let volumeURL: URL

    /// Returns the new database ID for each added track, keyed by source path.
    @concurrent
    func add(_ requests: [IPodSyncRequest]) async throws -> [String: UInt64] {
        let store = ITunesDBStore(volumeURL: volumeURL)
        var editor = try ITunesDBEditor(root: store.loadRecords())
        let pending = requests.filter { request in
            request.existingDatabaseID.map { !editor.containsTrack(databaseID: $0) } ?? true
        }
        try ensureFreeSpace(for: pending)
        var copied: [URL] = []
        do {
            let added = try copyAndRecord(pending, into: &editor, copied: &copied)
            try store.save(editor.serialized())
            return added
        } catch {
            copied.forEach { try? FileManager.default.removeItem(at: $0) }
            throw error
        }
    }

    private func copyAndRecord(_ requests: [IPodSyncRequest], into editor: inout ITunesDBEditor,
                               copied: inout [URL]) throws -> [String: UInt64] {
        let copier = IPodMusicFileCopier(volumeURL: volumeURL)
        var added: [String: UInt64] = [:]
        for request in requests {
            try Task.checkCancellation()
            let file = try copier.copy(request.sourceURL)
            copied.append(file.url)
            var draft = request.draft
            draft.location = file.location
            added[request.sourceURL.path(percentEncoded: false)] = editor.addTrack(draft)
        }
        return added
    }

    private func ensureFreeSpace(for requests: [IPodSyncRequest]) throws {
        let required = requests.reduce(Int64(0)) { $0 + Int64($1.draft.fileSize) }
        let values = try volumeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        let available = Int64(values.volumeAvailableCapacity ?? 0)
        guard required < available else {
            throw IPodSyncError.insufficientSpace(required: required, available: available)
        }
    }
}
