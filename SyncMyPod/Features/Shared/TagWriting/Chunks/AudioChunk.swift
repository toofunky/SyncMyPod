import Foundation

/// One chunk of a WAV or AIFF file: a four-character ID, a size, and a body padded to an even length.
nonisolated struct AudioChunk: Equatable, Sendable {
    static let headerLength = 8

    let id: String
    /// Where the chunk's header starts in the file.
    let offset: Int
    /// The body's length, without the pad byte.
    let size: Int

    var bodyOffset: Int { offset + Self.headerLength }
    var paddedLength: Int { Self.headerLength + size + size % 2 }
}
