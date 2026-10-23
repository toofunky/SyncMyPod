import Foundation

/// The files making up one book, with names to use when the files' tags don't say.
nonisolated struct AudiobookGroup: Equatable, Sendable {
    /// The book's folder, or its first file's path when the folder holds several books.
    let key: String
    let filePaths: [String]
    let fallbackTitle: String
    let fallbackAuthor: String
}
