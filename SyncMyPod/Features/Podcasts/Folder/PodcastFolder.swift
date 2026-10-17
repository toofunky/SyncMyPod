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
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.bookmarkKey) { open(bookmark: data) }
    }

    var path: String? { url?.path(percentEncoded: false) }

    func choose(_ newURL: URL, libraryFolderPaths: [String]) throws {
        if let overlap = Self.overlappingLibrary(newURL.path(percentEncoded: false), libraryFolderPaths) {
            throw PodcastFolderError.overlapsLibrary(overlap)
        }
        let data = try newURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil,
                                           relativeTo: nil)
        defaults.set(data, forKey: Self.bookmarkKey)
        open(bookmark: data)
    }

    /// The library folder `path` lies inside or contains, if any.
    nonisolated static func overlappingLibrary(_ path: String, _ libraryFolderPaths: [String]) -> String? {
        let folder = normalized(path)
        return libraryFolderPaths.first { library in
            let library = normalized(library)
            return folder.hasPrefix(library) || library.hasPrefix(folder)
        }
    }

    private func open(bookmark data: Data) {
        var isStale = false
        guard let resolved = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil,
                                      bookmarkDataIsStale: &isStale) else { return }
        if isStale, let fresh = try? resolved.bookmarkData(options: .withSecurityScope,
                                                           includingResourceValuesForKeys: nil, relativeTo: nil) {
            defaults.set(fresh, forKey: Self.bookmarkKey)
        }
        url?.stopAccessingSecurityScopedResource()
        _ = resolved.startAccessingSecurityScopedResource()
        url = resolved
    }

    /// With a trailing slash, so "/Music" doesn't count as containing "/Music Podcasts".
    private nonisolated static func normalized(_ path: String) -> String {
        let standardized = URL(filePath: path, directoryHint: .isDirectory).standardizedFileURL.path(percentEncoded: false)
        return standardized.hasSuffix("/") ? standardized : standardized + "/"
    }
}

#if DEBUG
extension PodcastFolder {
    static var preview: PodcastFolder {
        PodcastFolder(defaults: UserDefaults(suiteName: "PodcastFolderPreview") ?? .standard)
    }
}
#endif
