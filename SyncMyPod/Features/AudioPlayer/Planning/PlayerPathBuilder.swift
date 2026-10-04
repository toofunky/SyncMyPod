import Foundation

/// Where a library file goes on a player: `<music folder>/<Album Artist>/<Album>/<file>`.
nonisolated struct PlayerPathBuilder {
    let config: AudioPlayerConfig

    /// Relative to the volume.
    func path(for request: IPodSyncRequest) -> String {
        let draft = request.draft
        let artist = PlayerFileNamer.safeComponent(draft.albumListArtist, fallback: LibraryTrack.unknownArtist)
        let album = PlayerFileNamer.safeComponent(draft.album, fallback: LibraryTrack.unknownAlbum)
        return AudioPlayerConfig.join(config.musicPath, artist, album, fileName(for: request))
    }

    /// The library file's own name, or "<number> <title>.<ext>" when preserving track sorting.
    func fileName(for request: IPodSyncRequest) -> String {
        let original = request.sourceURL.lastPathComponent
        let ext = request.sourceURL.pathExtension.lowercased()
        let originalStem = request.sourceURL.deletingPathExtension().lastPathComponent
        guard config.preserveTrackSorting else { return PlayerFileNamer.safeComponent(original, fallback: "Track") }
        let draft = request.draft
        let title = PlayerFileNamer.safeComponent(draft.title, fallback: originalStem)
        let prefix = PlayerFileNamer.numberPrefix(disc: draft.discNumber, discCount: draft.discCount,
                                                  track: draft.trackNumber, trackCount: draft.trackCount)
        let stem = prefix.map { "\($0) \(title)" } ?? title
        return ext.isEmpty ? stem : "\(stem).\(ext)"
    }
}
