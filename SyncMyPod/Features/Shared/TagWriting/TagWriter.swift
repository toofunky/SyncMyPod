import Foundation

nonisolated struct TagWriter: Sendable {
    /// The most padding a write may leave behind before the tags are compacted instead; `nil` always writes in
    /// place when the tags fit, which keeps library edits fast.
    var maximumPadding: Int?

    @concurrent
    func write(_ changes: TagChanges, to url: URL, codec: AudioCodec) async throws {
        guard !changes.isEmpty else { return }
        switch codec {
        case .mp3: try ID3TagWriter(maximumPadding: maximumPadding).write(changes, to: url)
        case .aac, .alac: try MP4TagWriter(maximumPadding: maximumPadding).write(changes, to: url)
        case .flac: try FLACTagWriter(maximumPadding: maximumPadding).write(changes, to: url)
        case .aiff, .wav: try ChunkedID3TagWriter(maximumPadding: maximumPadding).write(changes, to: url)
        }
    }
}
