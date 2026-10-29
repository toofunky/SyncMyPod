import Foundation

/// A cover image or lyric file in the music library, as it was when looked at.
nonisolated struct SidecarFile: Codable, Equatable, Sendable {
    let path: String
    let fileSize: Int64
    let modificationDate: Date

    var url: URL { URL(filePath: path) }
    var fileName: String { (path as NSString).lastPathComponent }
}
