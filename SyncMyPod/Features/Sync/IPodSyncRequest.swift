import Foundation

nonisolated struct IPodSyncRequest: Equatable, Sendable {
    let sourceURL: URL
    let draft: ITunesTrackDraft
    /// `nil` until the library file has been scanned with artwork fingerprints.
    let source: SyncSource?

    init(sourceURL: URL, draft: ITunesTrackDraft, source: SyncSource? = nil) {
        self.sourceURL = sourceURL
        self.draft = draft
        self.source = source
    }

    var matchKey: IPodTrackMatchKey { IPodTrackMatchKey(draft) }
    var sourcePath: String { sourceURL.path(percentEncoded: false) }
}
