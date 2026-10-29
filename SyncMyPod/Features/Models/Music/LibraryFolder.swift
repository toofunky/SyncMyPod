import Foundation
import SwiftData

@Model
nonisolated final class LibraryFolder {
    var path: String
    var bookmarkData: Data
    var lastScanDate: Date?

    init(path: String, bookmarkData: Data) {
        self.path = path
        self.bookmarkData = bookmarkData
    }

    static func make(for url: URL) throws -> LibraryFolder {
        LibraryFolder(path: url.path(percentEncoded: false), bookmarkData: try bookmark(for: url))
    }

    func resolveURL() throws -> URL {
        var isStale = false
        let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope,
                          relativeTo: nil, bookmarkDataIsStale: &isStale)
        if isStale {
            bookmarkData = try Self.bookmark(for: url)
            path = url.path(percentEncoded: false)
        }
        return url
    }

    private static func bookmark(for url: URL) throws -> Data {
        try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil,
                             relativeTo: nil)
    }
}

#if DEBUG
extension LibraryFolder {
    static var preview: LibraryFolder {
        let folder = LibraryFolder(path: "/Users/me/Music/AAC", bookmarkData: Data())
        folder.lastScanDate = .now.addingTimeInterval(-3_600)
        return folder
    }
}
#endif
