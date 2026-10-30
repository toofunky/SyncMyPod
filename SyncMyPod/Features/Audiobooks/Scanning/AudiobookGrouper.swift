import Foundation

/// Splits the audiobook folder's files into books.
///
/// A folder of audio files is one book, with "CD 1" or "Disc 2" subfolders counting as part of it. A folder of
/// only .m4b files, or the audiobook folder itself, holds a book per album tag, or per file when untagged, so a
/// lone .m4b is a book of its own while several .m4b parts sharing an album stay together.
nonisolated struct AudiobookGrouper {
    let rootPath: String

    init(rootPath: String) {
        self.rootPath = Self.trimmed(rootPath)
    }

    func groups(for files: [AudiobookFileSummary]) -> [AudiobookGroup] {
        Dictionary(grouping: files) { bookFolder(of: $0.path) }
            .flatMap { folder, files in groups(in: folder, files: files) }
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
    }

    private func groups(in folder: String, files: [AudiobookFileSummary]) -> [AudiobookGroup] {
        let wholeFolder = [folderGroup(folder, paths: files.map(\.path))]
        guard folder == rootPath || files.allSatisfy(\.isM4B) else { return wholeFolder }
        let byAlbum = Dictionary(grouping: files) { $0.album.isEmpty ? $0.path : $0.album }
        if byAlbum.count == 1, files.count > 1, folder != rootPath { return wholeFolder }
        return byAlbum.values.map { book in
            let paths = Self.sorted(book.map(\.path))
            let fileName = (paths[0] as NSString).lastPathComponent
            return AudiobookGroup(key: paths[0], filePaths: paths,
                                  fallbackTitle: (fileName as NSString).deletingPathExtension,
                                  fallbackAuthor: folder == rootPath ? "" : name(of: folder))
        }
    }

    private func folderGroup(_ folder: String, paths: [String]) -> AudiobookGroup {
        AudiobookGroup(key: folder, filePaths: Self.sorted(paths), fallbackTitle: name(of: folder),
                       fallbackAuthor: author(above: folder))
    }

    /// The folder a file's book lives in, skipping up past disc subfolders.
    private func bookFolder(of path: String) -> String {
        var folder = (path as NSString).deletingLastPathComponent
        while folder.count > rootPath.count, isDiscFolder(folder) {
            folder = (folder as NSString).deletingLastPathComponent
        }
        return folder
    }

    private func isDiscFolder(_ folder: String) -> Bool {
        name(of: folder).isDiscFolderName
    }

    /// The parent folder's name, which is usually the author's, unless the parent is the audiobook folder.
    private func author(above folder: String) -> String {
        let parent = (folder as NSString).deletingLastPathComponent
        return parent.count > rootPath.count ? name(of: parent) : ""
    }

    private func name(of folder: String) -> String {
        (folder as NSString).lastPathComponent
    }

    private static func sorted(_ paths: [String]) -> [String] {
        paths.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private static func trimmed(_ path: String) -> String {
        path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
    }
}
