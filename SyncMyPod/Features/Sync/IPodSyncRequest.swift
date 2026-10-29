import Foundation

nonisolated struct IPodSyncRequest: Equatable, Sendable {
    let sourceURL: URL
    let draft: ITunesTrackDraft
    /// `nil` until the library file has been scanned with artwork fingerprints.
    let source: SyncSource?
    /// Whether the song's .lrc lyric file is written into the copy, which has no lyrics of its own.
    let embedsLyricsSidecar: Bool
    /// Podcast episodes and audiobooks are filed in a player's own folders for them instead of its music folder.
    let kind: SyncMediaKind
    /// An image file, such as an audiobook folder's cover.jpg, for the iPod's cover when the file has none.
    let coverImageURL: URL?

    init(sourceURL: URL, draft: ITunesTrackDraft, source: SyncSource? = nil, embedsLyricsSidecar: Bool = false,
         kind: SyncMediaKind = .music, coverImageURL: URL? = nil) {
        self.sourceURL = sourceURL
        self.draft = draft
        self.source = source
        self.embedsLyricsSidecar = embedsLyricsSidecar
        self.kind = kind
        self.coverImageURL = coverImageURL
    }

    var sourcePath: String { sourceURL.path(percentEncoded: false) }
}
