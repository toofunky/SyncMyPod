import Foundation
import Observation

/// A user-chosen folder, remembered as a bookmark and kept open for the app's lifetime.
@MainActor
@Observable
final class ManagedFolder {
    private(set) var url: URL?
    @ObservationIgnored private let bookmark: FolderBookmark

    init(bookmarkKey: String, defaults: UserDefaults) {
        bookmark = FolderBookmark(key: bookmarkKey, defaults: defaults)
        if let resolved = bookmark.resolve() { open(resolved) }
    }

    var path: String? { url?.path(percentEncoded: false) }

    func save(_ newURL: URL) throws {
        try bookmark.save(newURL)
        open(newURL)
    }

    private func open(_ resolved: URL) {
        url?.stopAccessingSecurityScopedResource()
        _ = resolved.startAccessingSecurityScopedResource()
        url = resolved
    }
}
