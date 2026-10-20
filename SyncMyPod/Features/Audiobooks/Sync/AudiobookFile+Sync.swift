import Foundation

extension AudiobookFile {
    static let syncGenre = "Audiobooks"

    /// Numbered by its place in the book, so the parts list in listening order whatever their own tags say.
    /// Like a podcast episode, a player's request has no `SyncSource`, so a copy already on it is never replaced
    /// and the player can't forget where it was. `nil` for audio an iPod can't play.
    func syncRequest(book: Audiobook, part: Int, of partCount: Int, forIPod: Bool) -> IPodSyncRequest? {
        guard !forIPod || codec?.syncsToIPod == true else { return nil }
        var draft = ITunesTrackDraft(title: title, artist: book.author, album: book.title, albumArtist: book.author,
                                     genre: Self.syncGenre, fileSize: fileSize, duration: duration,
                                     trackNumber: part, trackCount: partCount, bitrate: bitrate,
                                     sampleRate: sampleRate, dateAdded: book.dateAdded,
                                     lastModified: modificationDate, codec: codec ?? .aac)
        draft.mediaKind = forIPod ? .audiobook : .music
        return IPodSyncRequest(sourceURL: fileURL, draft: draft, source: forIPod ? syncSource : nil, kind: .audiobook)
    }

    /// `nil` until the file has been scanned, so the manifest never records a stale size.
    private var syncSource: SyncSource? {
        guard scanVersion == Self.currentScanVersion else { return nil }
        return SyncSource(fileSize: fileSize, modificationDate: modificationDate,
                          artworkFingerprint: artworkFingerprint)
    }
}
