import Foundation

/// The cover images and lyric files beside the library's songs.
nonisolated struct LibrarySidecars: Equatable, Sendable {
    /// Keyed by folder path, in the order players prefer them.
    var covers: [String: [SidecarFile]] = [:]
    /// Keyed by the song file's path.
    var lyrics: [String: SidecarFile] = [:]

    var isEmpty: Bool { covers.isEmpty && lyrics.isEmpty }

    func covers(besideSongAt path: String) -> [SidecarFile] {
        covers[(path as NSString).deletingLastPathComponent] ?? []
    }
}
