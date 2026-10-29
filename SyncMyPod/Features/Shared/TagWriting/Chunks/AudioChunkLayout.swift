import Foundation

/// The chunks of a WAV or AIFF file, and where the container its header describes ends.
nonisolated struct AudioChunkLayout: Sendable {
    let format: AudioChunkFormat
    let chunks: [AudioChunk]
    /// The end of the container, or of the file when that's shorter.
    let end: Int

    var id3Chunk: AudioChunk? { chunks.first { format.isID3Chunk($0.id) } }
}
