import Foundation

/// Copies a batch's files and records them in the databases, remembering what to undo or clean up.
nonisolated struct IPodBatchWriter {
    var editor: ITunesDBEditor
    var artwork: ArtworkSyncSession
    var outcome: IPodSyncOutcome
    let copier: IPodMusicFileCopier
    let albumTracks: [IPodAlbumKey: [UInt64]]
    /// New audio files, deleted if the sync fails.
    private(set) var copied: [URL] = []
    /// Audio files that updated tracks no longer use, deleted once the databases are saved.
    private(set) var replacedLocations: [String] = []

    init(editor: ITunesDBEditor, artwork: ArtworkSyncSession, outcome: IPodSyncOutcome, copier: IPodMusicFileCopier,
         albumTracks: [IPodAlbumKey: [UInt64]]) {
        self.editor = editor
        self.artwork = artwork
        self.outcome = outcome
        self.copier = copier
        self.albumTracks = albumTracks
    }

    mutating func write(_ item: SyncBatchItem) async throws {
        switch item {
        case .add(let request): try await add(request)
        case .update(let update): try await self.update(update)
        }
    }

    /// Replaces the playlists earlier syncs wrote, pointing at the tracks as they are after this batch.
    mutating func writePlaylists(_ playlists: [IPodPlaylistRequest], resolver: PlaylistTrackResolver) {
        let drafts = playlists.map { resolver.draft(for: $0, synced: outcome.syncedDatabaseIDs) }
        editor.replacePlaylists(drafts, removing: resolver.manifest.playlistIDs)
        outcome.syncedPlaylistCount = drafts.count
    }

    private mutating func add(_ request: IPodSyncRequest) async throws {
        var draft = try copy(request)
        let prepared = try await artwork.prepare(coverFrom: request.sourceURL,
                                                 albumTracks: albumTracks[IPodAlbumKey(draft)] ?? [])
        draft.artwork = prepared?.trackArtwork
        let databaseID = editor.addTrack(draft)
        if let prepared { artwork.attach(prepared, toTrack: databaseID) }
        outcome.addedDatabaseIDs[request.sourcePath] = databaseID
    }

    /// Replaces the audio file and rewrites the record; the cover is redrawn only if it changed.
    private mutating func update(_ update: IPodTrackUpdate) async throws {
        var draft = try copy(update.request)
        if update.artworkChanged {
            artwork.removeImages(forTracks: [update.databaseID])
            let others = (albumTracks[IPodAlbumKey(draft)] ?? []).filter { $0 != update.databaseID }
            let prepared = try await artwork.prepare(coverFrom: update.request.sourceURL, albumTracks: others)
            draft.artwork = prepared?.trackArtwork
            if let prepared { artwork.attach(prepared, toTrack: update.databaseID) }
        }
        let previous = editor.updateTrack(databaseID: update.databaseID, with: draft,
                                          keepingArtwork: !update.artworkChanged)
        if let previous, !previous.isEmpty { replacedLocations.append(previous) }
        outcome.updatedDatabaseIDs[update.request.sourcePath] = update.databaseID
    }

    private mutating func copy(_ request: IPodSyncRequest) throws -> ITunesTrackDraft {
        let file = try copier.copy(request.sourceURL)
        copied.append(file.url)
        var draft = request.draft
        draft.location = file.location
        return draft
    }
}
