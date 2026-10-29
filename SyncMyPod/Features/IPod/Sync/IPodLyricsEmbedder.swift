import Foundation

/// Writes a song's .lrc lyric file into its copy on the iPod as plain lyrics.
nonisolated struct IPodLyricsEmbedder: Sendable {
    /// Returns the copy's new size, or `nil` when the lyric file is missing, unreadable or empty,
    /// leaving the copy as it was.
    @concurrent
    func embed(lyricsOf sourcePath: String, into copyURL: URL, codec: AudioCodec) async throws -> Int? {
        guard let lrc = try? await LyricsFile.read(forSongAt: sourcePath) else { return nil }
        let lyrics = LRCLyrics.plainText(from: lrc)
        guard !lyrics.isEmpty else { return nil }
        try await TagWriter().write(TagChanges(lyrics: lyrics), to: copyURL, codec: codec)
        return try copyURL.resourceValues(forKeys: [.fileSizeKey]).fileSize
    }
}
