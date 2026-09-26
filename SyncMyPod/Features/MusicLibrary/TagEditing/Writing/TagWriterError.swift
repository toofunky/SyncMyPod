import Foundation

nonisolated enum TagWriterError: LocalizedError, Equatable {
    case unexpectedEndOfFile
    case malformedFile(String)
    case missingMovieBox
    case chunkOffsetOverflow

    var errorDescription: String? {
        switch self {
        case .unexpectedEndOfFile: "The file ended unexpectedly."
        case .malformedFile(let detail): "The file's structure couldn't be read (\(detail))."
        case .missingMovieBox: "The file has no movie box to hold tags."
        case .chunkOffsetOverflow: "The file is too large to add tags to."
        }
    }
}
