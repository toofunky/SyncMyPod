import Foundation

/// Which songs have a lyric file beside them, listing each song folder once.
nonisolated struct LyricsFileIndex {
    private var lyricPaths: Set<String> = []

    init(besideSongsAt paths: [String]) {
        for folder in Set(paths.map { ($0 as NSString).deletingLastPathComponent }) {
            let names = (try? FileManager.default.contentsOfDirectory(atPath: folder)) ?? []
            for name in names where (name as NSString).pathExtension.lowercased() == LyricsFile.fileExtension {
                lyricPaths.insert(Self.key(folder: folder, name: name.lowercased()))
            }
        }
    }

    func hasLyrics(forSongAt path: String) -> Bool {
        let folder = (path as NSString).deletingLastPathComponent
        return lyricPaths.contains(Self.key(folder: folder, name: LyricsFile.matchingName(forSongAt: path)))
    }

    private static func key(folder: String, name: String) -> String {
        (folder as NSString).appendingPathComponent(name)
    }
}
