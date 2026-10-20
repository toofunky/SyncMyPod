import Foundation
import Observation

/// The user-chosen folder audiobooks are scanned from, remembered as a bookmark and kept open for the app's lifetime.
@MainActor
@Observable
final class AudiobookFolder {
    #if DEBUG
    /// Debug builds keep their own library, so they get their own folder setting too.
    static let bookmarkKey = "audiobookFolderBookmarkDebug"
    #else
    static let bookmarkKey = "audiobookFolderBookmark"
    #endif

    private(set) var url: URL?
    @ObservationIgnored private let bookmark: FolderBookmark

    init(defaults: UserDefaults = .standard) {
        bookmark = FolderBookmark(key: Self.bookmarkKey, defaults: defaults)
        if let resolved = bookmark.resolve() { open(resolved) }
    }

    var path: String? { url?.path(percentEncoded: false) }

    func choose(_ newURL: URL, libraryFolderPaths: [String], podcastFolderPath: String?) throws {
        let newPath = newURL.path(percentEncoded: false)
        if let overlap = FolderOverlap.first(newPath, in: libraryFolderPaths) {
            throw AudiobookFolderError.overlapsLibrary(overlap)
        }
        if let overlap = FolderOverlap.first(newPath, in: podcastFolderPath.map { [$0] } ?? []) {
            throw AudiobookFolderError.overlapsPodcasts(overlap)
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
extension AudiobookFolder {
    static var preview: AudiobookFolder {
        AudiobookFolder(defaults: UserDefaults(suiteName: "AudiobookFolderPreview") ?? .standard)
    }
}
#endif
