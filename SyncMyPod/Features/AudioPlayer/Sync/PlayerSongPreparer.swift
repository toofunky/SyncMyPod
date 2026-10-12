import Foundation

/// Builds the copy of a song that differs from its library file, retagged or with smaller artwork, in a local
/// temporary folder, so the player is written once with the finished file instead of being rewritten over a
/// slow connection such as a network share.
nonisolated struct PlayerSongPreparer {
    /// The most padding a copy keeps after its tags shrink, as when a large cover is replaced by a small one, so
    /// it doesn't carry megabytes of empty space. Smaller padding stays, so later tag edits fit in place.
    static let maximumPadding = 64 * 1_024

    /// Empty when the copy is the library file as it is.
    static func changes(for request: IPodSyncRequest) async -> TagChanges {
        var changes = request.playerTagChanges ?? TagChanges()
        if let limit = request.source?.artworkPixelLimit,
           let artwork = await EmbeddedArtworkResizer().resizedArtwork(of: request.sourceURL, within: limit) {
            changes.artwork = .replace(artwork)
        }
        return changes
    }

    /// The prepared file is alone in its own temporary folder, which the caller removes. An .m4a also gets
    /// its `moov` box first.
    func prepare(_ request: IPodSyncRequest, with changes: TagChanges) async throws -> URL {
        let manager = FileManager.default
        let folder = manager.temporaryDirectory.appending(path: "SyncMyPod-\(UUID().uuidString)",
                                                          directoryHint: .isDirectory)
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        let prepared = folder.appending(path: request.sourceURL.lastPathComponent)
        do {
            if try !MP4FastStartCopier().copy(request.sourceURL, to: prepared) {
                try manager.copyItem(at: request.sourceURL, to: prepared)
            }
            try await TagWriter(maximumPadding: Self.maximumPadding)
                .write(changes, to: prepared, codec: request.draft.codec)
        } catch {
            try? manager.removeItem(at: folder)
            throw error
        }
        return prepared
    }
}
