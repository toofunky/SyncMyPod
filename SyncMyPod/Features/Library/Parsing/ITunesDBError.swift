import Foundation

nonisolated enum ITunesDBError: Error, Equatable, LocalizedError {
    case databaseNotFound(path: String)
    case truncated(offset: Int)
    case unexpectedTag(expected: String, found: String, offset: Int)
    case invalidLength(offset: Int)

    var errorDescription: String? {
        switch self {
        case .databaseNotFound(let path):
            "No iTunesDB was found at \(path)."
        case .truncated(let offset):
            "The iTunesDB ended unexpectedly at byte \(offset)."
        case .unexpectedTag(let expected, let found, let offset):
            "Expected a \(expected) record at byte \(offset) but found \"\(found)\"."
        case .invalidLength(let offset):
            "The record at byte \(offset) has an invalid length."
        }
    }
}
