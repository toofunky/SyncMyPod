import Foundation
import Observation

/// The podcast download and audiobook folders, kept apart from each other and from the music folder.
@MainActor
@Observable
final class MediaFolders {
    #if DEBUG
    /// Debug builds keep their own library, so they get their own folders and never delete the release app's files.
    private static let podcastsKey = "podcastFolderBookmarkDebug"
    private static let audiobooksKey = "audiobookFolderBookmarkDebug"
    #else
    private static let podcastsKey = "podcastFolderBookmark"
    private static let audiobooksKey = "audiobookFolderBookmark"
    #endif

    let podcasts: ManagedFolder
    let audiobooks: ManagedFolder

    init(defaults: UserDefaults = .standard) {
        podcasts = ManagedFolder(bookmarkKey: Self.podcastsKey, defaults: defaults)
        audiobooks = ManagedFolder(bookmarkKey: Self.audiobooksKey, defaults: defaults)
    }

    /// Throws a `FolderOverlapError` instead when the folder overlaps one of the others.
    func choose(_ url: URL, as kind: MediaFolderKind, musicFolderPath: String?) throws {
        if let overlap = overlap(of: url.path(percentEncoded: false), as: kind, musicFolderPath: musicFolderPath) {
            throw overlap
        }
        switch kind {
        case .music: break
        case .podcasts: try podcasts.save(url)
        case .audiobooks: try audiobooks.save(url)
        }
    }

    /// The music folder is chosen elsewhere, so it's checked with `kind` `.music` and a `nil` music path.
    func overlap(of path: String, as kind: MediaFolderKind, musicFolderPath: String?) -> FolderOverlapError? {
        let paths: [MediaFolderKind: String?] = [.music: musicFolderPath, .podcasts: podcasts.path,
                                                 .audiobooks: audiobooks.path]
        return FolderOverlapError.check(path, as: kind, against: paths.compactMapValues { $0 })
    }
}

#if DEBUG
extension MediaFolders {
    static var preview: MediaFolders {
        MediaFolders(defaults: UserDefaults(suiteName: "MediaFoldersPreview") ?? .standard)
    }
}
#endif
