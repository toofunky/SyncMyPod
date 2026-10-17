import Foundation

nonisolated struct PodcastDownloadResult: Equatable, Sendable {
    let fileURL: URL
    let byteCount: Int64
    /// Read from the file, which is more reliable than the feed's `itunes:duration`; `nil` if it couldn't be read.
    let duration: TimeInterval?
}
