import Foundation

extension Audiobook {
    var syncKey: String { bookID.uuidString }

    /// Stable across syncs, like a podcast's, so the book's playlist is replaced rather than duplicated.
    var syncPlaylistID: UInt64 {
        withUnsafeBytes(of: bookID.uuid) { $0.loadUnaligned(as: UInt64.self) }
    }

    /// The book's files in listening order; `nil` when it has none, or none an iPod can play.
    func syncSnapshot(forIPod: Bool = false) -> SyncAudiobookSnapshot? {
        let sorted = sortedFiles
        let requests = sorted.enumerated().compactMap { index, file in
            file.syncRequest(book: self, part: index + 1, of: sorted.count, forIPod: forIPod)
        }
        guard !requests.isEmpty else { return nil }
        return SyncAudiobookSnapshot(key: syncKey, title: title, author: author, files: requests,
                                     playlistID: syncPlaylistID, createdAt: dateAdded)
    }
}
