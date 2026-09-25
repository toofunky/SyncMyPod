import Foundation

nonisolated struct AudioFileMetadata: Equatable, Sendable {
    let tags: AudioTags
    let duration: TimeInterval
    let bitrate: Int
    let sampleRate: Int
}
