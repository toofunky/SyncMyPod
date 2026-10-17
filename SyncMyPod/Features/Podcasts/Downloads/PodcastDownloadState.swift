import Foundation

nonisolated enum PodcastDownloadState: Equatable, Sendable {
    case queued
    /// The fraction downloaded, or `nil` while the server hasn't said how large the file is.
    case downloading(Double?)
}
