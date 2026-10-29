import Foundation

nonisolated struct ScannedAudioFile: Equatable, Sendable {
    let url: URL
    let fileSize: Int
    let modificationDate: Date

    var path: String { url.path(percentEncoded: false) }
}
