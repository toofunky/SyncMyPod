import Foundation

nonisolated struct IPodSyncRequest: Equatable, Sendable {
    let sourceURL: URL
    let draft: ITunesTrackDraft
    /// `nil` until the library file has been scanned with artwork fingerprints.
    let source: SyncSource?
    /// Whether the song's .lrc lyric file is written into the copy, which has no lyrics of its own.
    let embedsLyricsSidecar: Bool

    init(sourceURL: URL, draft: ITunesTrackDraft, source: SyncSource? = nil, embedsLyricsSidecar: Bool = false) {
        self.sourceURL = sourceURL
        self.draft = draft
        self.source = source
        self.embedsLyricsSidecar = embedsLyricsSidecar
    }

    var matchKey: IPodTrackMatchKey { IPodTrackMatchKey(draft) }
    var sourcePath: String { sourceURL.path(percentEncoded: false) }
}
