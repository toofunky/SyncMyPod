import Foundation
import SwiftData

/// A book found in the audiobook folder: a folder of audio files, or a single .m4b file.
@Model
nonisolated final class Audiobook {
    @Attribute(.unique) var bookID: UUID
    /// The book's folder, or the .m4b file's path for a single-file book.
    @Attribute(.unique) var folderPath: String
    var title: String
    var author = ""
    /// The book folder's cover.jpg, folder.jpg, cover.png or folder.png, for books whose files have no artwork.
    var coverFilePath: String?
    /// When the cover file last changed, so editing it updates the copies on an iPod.
    var coverFileDate: Date?
    var dateAdded: Date
    /// The file where listening in the app stopped; `nil` when the book is unstarted or finished.
    var currentFilePath: String?
    /// Seconds into `currentFilePath` where listening stopped.
    var playbackPosition: TimeInterval = 0
    @Relationship(deleteRule: .cascade, inverse: \AudiobookFile.book) var files: [AudiobookFile] = []

    init(folderPath: String, title: String) {
        bookID = UUID()
        self.folderPath = folderPath
        self.title = title
        dateAdded = .now
    }

    /// Listening order: disc, then track number, then filename.
    var sortedFiles: [AudiobookFile] { files.sorted(by: AudiobookFile.playsBefore) }

    var duration: TimeInterval { files.reduce(0) { $0 + $1.duration } }

    var byteCount: Int { files.reduce(0) { $0 + $1.fileSize } }

    /// Seconds already listened to, counting every file before the current one.
    var elapsed: TimeInterval {
        guard let currentFilePath else { return 0 }
        let before = sortedFiles.prefix { $0.filePath != currentFilePath }
        return before.reduce(0) { $0 + $1.duration } + playbackPosition
    }

    var isStarted: Bool { currentFilePath != nil }

    /// The first file with embedded artwork, which stands for the whole book.
    var artworkFile: AudiobookFile? { sortedFiles.first { $0.artworkFingerprint != nil } }

    /// What to draw the book's cover from: its first file with embedded artwork, or else its folder's cover
    /// image. The fingerprint keys the artwork cache.
    var artwork: (path: String, fingerprint: String)? {
        if let file = artworkFile, let fingerprint = file.artworkFingerprint { return (file.filePath, fingerprint) }
        return coverFilePath.map { ($0, Self.coverFingerprint(path: $0, date: coverFileDate)) }
    }

    static func coverFingerprint(path: String, date: Date?) -> String {
        "cover:\(path)#\(date?.timeIntervalSinceReferenceDate ?? 0)"
    }

    static let titleOrder = [SortDescriptor(\Audiobook.title, comparator: .localizedStandard)]
}

#if DEBUG
extension Audiobook {
    static let preview: Audiobook = {
        let book = Audiobook(folderPath: "/Users/me/Audiobooks/Mary Shelley/Frankenstein", title: "Frankenstein")
        book.author = "Mary Shelley"
        book.files = AudiobookFile.previewFiles
        book.currentFilePath = book.files[1].filePath
        book.playbackPosition = 754
        return book
    }()
}
#endif
