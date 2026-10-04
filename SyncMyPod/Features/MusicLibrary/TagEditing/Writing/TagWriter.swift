import Foundation

nonisolated struct TagWriter: Sendable {
    @concurrent
    func write(_ changes: TagChanges, to url: URL, codec: AudioCodec) async throws {
        guard !changes.isEmpty else { return }
        switch codec {
        case .mp3: try ID3TagWriter().write(changes, to: url)
        case .aac, .alac: try MP4TagWriter().write(changes, to: url)
        case .flac: try FLACTagWriter().write(changes, to: url)
        }
    }
}
