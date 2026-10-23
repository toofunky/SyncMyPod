import Foundation
import Observation

/// The user-chosen folder episodes download into, remembered as a bookmark and kept open for the app's lifetime.
@MainActor
@Observable
final class PodcastFolder {
    #if DEBUG
    /// Debug builds keep their own library, so they get their own folder and never delete the release app's files.
    static let bookmarkKey = "podcastFolderBookmarkDebug"
    #else
    static let bookmarkKey = "podcastFolderBookmark"
    #endif

    private(set) var url: URL?
    @ObservationIgnored private let bookmark: FolderBookmark

    init(defaults: UserDefaults = .standard) {
        bookmark = FolderBookmark(key: Self.bookmarkKey, defaults: defaults)
        if let resolved = bookmark.resolve() { open(resolved) }
    }

    var path: String? { url?.path(percentEncoded: false) }

    func choose(_ newURL: URL, libraryFolderPaths: [String], audiobookFolderPath: String?) throws {
        let newPath = newURL.path(percentEncoded: false)
        if let overlap = FolderOverlap.first(newPath, in: libraryFolderPaths) {
            throw PodcastFolderError.overlapsLibrary(overlap)
        }
        if let overlap = FolderOverlap.first(newPath, in: audiobookFolderPath.map { [$0] } ?? []) {
            throw PodcastFolderError.overlapsAudiobooks(overlap)
        }
        try bookmark.save(newURL)
        open(newURL)
    }

    private func open(_ resolved: URL) {
        url?.stopAccessingSecurityScopedResource()
        _ = resolved.startAccessingSecurityScopedResource()
        url = resolved
    }
}

#if DEBUG
extension PodcastFolder {
    static var preview: PodcastFolder {
        PodcastFolder(defaults: UserDefaults(suiteName: "PodcastFolderPreview") ?? .standard)
    }
}
#endif
