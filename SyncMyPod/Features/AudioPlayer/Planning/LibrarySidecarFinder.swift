import Foundation

/// Finds cover images and lyric files beside songs, matching names regardless of case.
nonisolated enum LibrarySidecarFinder {
    static let coverNames = ["cover.jpg", "folder.jpg", "cover.png", "folder.png"]

    /// Lists each song folder once.
    @concurrent
    static func find(besideSongsAt paths: [String], covers: Bool, lyrics: Bool) async -> LibrarySidecars {
        guard covers || lyrics else { return LibrarySidecars() }
        var sidecars = LibrarySidecars()
        let songsByFolder = Dictionary(grouping: paths) { ($0 as NSString).deletingLastPathComponent }
        for (folder, songs) in songsByFolder {
            let names = Self.names(in: folder)
            if covers {
                let found = coverFiles(in: folder, names: names)
                if !found.isEmpty { sidecars.covers[folder] = found }
            }
            if lyrics {
                for song in songs { sidecars.lyrics[song] = lyricFile(for: song, in: folder, names: names) }
            }
        }
        return sidecars
    }

    /// Keyed by lowercased name, so "Cover.JPG" is found as "cover.jpg".
    private static func names(in folder: String) -> [String: String] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder)) ?? []
        return Dictionary(names.map { ($0.lowercased(), $0) }, uniquingKeysWith: { first, _ in first })
    }

    private static func coverFiles(in folder: String, names: [String: String]) -> [SidecarFile] {
        coverNames.compactMap { names[$0] }.compactMap { file(at: (folder as NSString).appendingPathComponent($0)) }
    }

    private static func lyricFile(for song: String, in folder: String, names: [String: String]) -> SidecarFile? {
        let stem = ((song as NSString).lastPathComponent as NSString).deletingPathExtension
        guard let name = names[(stem + ".lrc").lowercased()] else { return nil }
        return file(at: (folder as NSString).appendingPathComponent(name))
    }

    private static func file(at path: String) -> SidecarFile? {
        let values = try? URL(filePath: path).resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey,
                                                                        .isRegularFileKey])
        guard values?.isRegularFile == true, let size = values?.fileSize,
              let modified = values?.contentModificationDate else { return nil }
        return SidecarFile(path: path, fileSize: Int64(size), modificationDate: modified)
    }
}
