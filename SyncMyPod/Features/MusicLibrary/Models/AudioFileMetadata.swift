import Foundation

nonisolated struct AudioFileMetadata: Equatable, Sendable {
    let codec: AudioCodec
    let tags: AudioTags
    let duration: TimeInterval
    let bitrate: Int
    let sampleRate: Int
    let artworkFingerprint: String?
}
