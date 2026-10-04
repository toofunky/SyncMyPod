import Foundation

/// A song's .lrc lyric file: in the song's folder with the song's name, matched regardless of case.
nonisolated enum LyricsFile {
    static let fileExtension = "lrc"

    /// The lowercased name a song's lyric file matches, such as "01 clocks.lrc".
    static func matchingName(forSongAt path: String) -> String {
        let stem = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        return "\(stem).\(fileExtension)".lowercased()
    }

    /// Returns `nil` when the song has no lyric file.
    @concurrent
    static func read(forSongAt path: String) async throws -> String? {
        guard let url = existingURL(forSongAt: path) else { return nil }
        var encoding = String.Encoding.utf8
        return try String(contentsOf: url, usedEncoding: &encoding)
    }

    /// Replaces an existing file under its own name, so "Clocks.LRC" isn't joined by "Clocks.lrc".
    @concurrent
    static func write(_ text: String, forSongAt path: String) async throws {
        let url = existingURL(forSongAt: path)
            ?? URL(filePath: path).deletingPathExtension().appendingPathExtension(fileExtension)
        try Data(text.utf8).write(to: url, options: .atomic)
    }

    @concurrent
    static func remove(forSongAt path: String) async throws {
        guard let url = existingURL(forSongAt: path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private static func existingURL(forSongAt path: String) -> URL? {
        let folder = (path as NSString).deletingLastPathComponent
        let name = matchingName(forSongAt: path)
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder)) ?? []
        return names.first { $0.lowercased() == name }.map { URL(filePath: folder).appending(path: $0) }
    }
}
