import AVFoundation

/// Reads the plain lyrics stored in a song's tags, which the iPod shows.
nonisolated struct EmbeddedLyricsReader: Sendable {
    /// Returns an empty string when the song has no lyrics.
    @concurrent
    func read(_ url: URL) async throws -> String {
        let items = try await AVURLAsset(url: url).load(.metadata)
        return try await items.lyrics?.load(.stringValue) ?? ""
    }
}
