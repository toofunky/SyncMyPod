import Foundation

extension AudiobookFile {
    static let syncGenre = "Audiobooks"

    /// Numbered by its place in the book, so the parts list in listening order whatever their own tags say.
    /// Like a podcast episode, a player's request has no `SyncSource`, so a copy already on it is never replaced
    /// and the player can't forget where it was. `nil` for audio an iPod can't play.
    func syncRequest(book: Audiobook, part: Int, of partCount: Int, forIPod: Bool) -> SyncRequest? {
        guard !forIPod || codec?.syncsToIPod == true else { return nil }
        var draft = ITunesTrackDraft(title: title, artist: book.author, album: book.title, albumArtist: book.author,
                                     genre: Self.syncGenre, fileSize: fileSize, duration: duration,
                                     trackNumber: part, trackCount: partCount, bitrate: bitrate,
                                     sampleRate: sampleRate, dateAdded: book.dateAdded,
                                     lastModified: modificationDate, codec: codec ?? .aac)
        draft.mediaKind = forIPod ? .audiobook : .music
        let cover = artworkFingerprint == nil ? book.coverFilePath : nil
        return SyncRequest(sourceURL: fileURL, draft: draft, source: forIPod ? syncSource(book: book) : nil,
                               kind: .audiobook, coverImageURL: cover.map { URL(filePath: $0) })
    }

    /// `nil` until the file has been scanned, so the manifest never records a stale size. A file without
    /// artwork of its own takes the book's cover image, whose fingerprint changes when the image does.
    private func syncSource(book: Audiobook) -> SyncSource? {
        guard scanVersion == Self.currentScanVersion else { return nil }
        let cover = book.coverFilePath.map { Audiobook.coverFingerprint(path: $0, date: book.coverFileDate) }
        return SyncSource(fileSize: fileSize, modificationDate: modificationDate,
                          artworkFingerprint: artworkFingerprint ?? cover)
    }
}
