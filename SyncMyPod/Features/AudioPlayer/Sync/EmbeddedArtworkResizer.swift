import AVFoundation

/// Scales a song's embedded cover down for a player's copy. It reads the library file, since the staged copy's
/// temporary name doesn't tell AVFoundation what kind of file it is, and the copy's artwork is the same.
nonisolated struct EmbeddedArtworkResizer: Sendable {
    /// `nil` when the song has no cover, its cover already fits, or the cover can't be read, so the copy keeps
    /// whatever artwork it has rather than failing the sync.
    @concurrent
    func resizedArtwork(of url: URL, within pixelLimit: Int) async -> Data? {
        guard let items = try? await AVURLAsset(url: url).load(.metadata),
              let item = items.coverArt,
              let data = try? await item.load(.dataValue) else { return nil }
        return try? CoverResizer.fitted(data, within: pixelLimit)
    }
}
