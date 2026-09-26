import Foundation

/// A library track's sync values, copied off the model so planning can run away from the main actor.
nonisolated struct SyncTrackSnapshot: Equatable, Sendable {
    let filePath: String
    let artist: String
    let album: String
    let albumKey: String
    let genre: String
    let request: IPodSyncRequest

    var byteCount: Int64 { Int64(request.draft.fileSize) }
}
