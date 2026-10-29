import Foundation

/// A book's files as a sync plans them, in listening order, copied off the model like library tracks are.
nonisolated struct SyncAudiobookSnapshot: Equatable, Sendable {
    let key: String
    let title: String
    let author: String
    let files: [SyncRequest]
    /// Stable across syncs, so the book's playlist is replaced rather than duplicated.
    var playlistID: UInt64 = 0
    var createdAt = Date.distantPast

    var byteCount: Int64 { files.reduce(0) { $0 + Int64($1.draft.fileSize) } }

    /// The book's files in listening order, so the iPod or player plays one book at a time instead of mixing
    /// every book's parts together.
    var playlist: SyncPlaylistRequest {
        SyncPlaylistRequest(id: playlistID, name: title, createdAt: createdAt, tracks: files)
    }
}
