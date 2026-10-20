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
    @Attribute(.externalStorage) var artworkData: Data?
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
