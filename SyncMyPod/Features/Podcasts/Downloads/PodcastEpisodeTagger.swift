import Foundation

/// Tags a freshly downloaded episode. Runs once per download and never again, because rewriting a file that's
/// already on a player could make it look like a new track and lose the player's saved position.
nonisolated enum PodcastEpisodeTagger {
    /// The file's audio details after tagging, or `nil` when it isn't audio the app can read or tag.
    @concurrent
    static func tag(_ url: URL, with tags: PodcastEpisodeTags) async throws -> AudioFileMetadata? {
        guard let metadata = try? await AudioMetadataReader().read(url) else { return nil }
        var changes = tags.changes
        if metadata.artworkFingerprint == nil, let artwork = tags.showArtwork {
            changes.artwork = .replace(artwork)
        }
        try await TagWriter().write(changes, to: url, codec: metadata.codec)
        return metadata
    }
}
