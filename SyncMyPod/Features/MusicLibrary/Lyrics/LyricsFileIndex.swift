import Foundation

/// Which songs have a lyric file beside them, and when it was modified, listing each song folder once.
nonisolated struct LyricsFileIndex {
    private var lyricDates: [String: Date] = [:]

    init(besideSongsAt paths: [String]) {
        for folder in Set(paths.map { ($0 as NSString).deletingLastPathComponent }) {
            let urls = (try? FileManager.default.contentsOfDirectory(
                at: URL(filePath: folder), includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
            for url in urls where url.pathExtension.lowercased() == LyricsFile.fileExtension {
                let date = LyricsFile.modificationDate(of: url) ?? .distantPast
                lyricDates[Self.key(folder: folder, name: url.lastPathComponent.lowercased())] = date
            }
        }
    }

    func hasLyrics(forSongAt path: String) -> Bool {
        lyricsDate(forSongAt: path) != nil
    }

    func lyricsDate(forSongAt path: String) -> Date? {
        let folder = (path as NSString).deletingLastPathComponent
        return lyricDates[Self.key(folder: folder, name: LyricsFile.matchingName(forSongAt: path))]
    }

    private static func key(folder: String, name: String) -> String {
        (folder as NSString).appendingPathComponent(name)
    }
}
