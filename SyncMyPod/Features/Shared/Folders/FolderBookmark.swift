import Foundation

/// A folder remembered as a security-scoped bookmark under one `UserDefaults` key.
nonisolated struct FolderBookmark {
    let key: String
    let defaults: UserDefaults

    /// The saved folder, re-saving the bookmark when macOS reports it stale.
    func resolve() -> URL? {
        guard let data = defaults.data(forKey: key) else { return nil }
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil,
                                 bookmarkDataIsStale: &isStale) else { return nil }
        if isStale { try? save(url) }
        return url
    }

    func save(_ url: URL) throws {
        let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil,
                                        relativeTo: nil)
        defaults.set(data, forKey: key)
    }
}
