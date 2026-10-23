import Foundation

/// Where a library file goes on a player: `<music folder>/<Album Artist>/<Album>/<file>`, for a podcast
/// episode `<podcast folder>/<Show>/<file>`, keeping the downloaded name that sorts episodes by date, and for an
/// audiobook `<audiobook folder>/<Author>/<Book>/<file>`, keeping the name that puts its parts in order.
nonisolated struct PlayerPathBuilder {
    let config: AudioPlayerConfig

    /// Relative to the volume.
    func path(for request: IPodSyncRequest) -> String {
        let draft = request.draft
        switch request.kind {
        case .podcast:
            let show = PlayerFileNamer.safeComponent(draft.album, fallback: "Podcast")
            let file = PlayerFileNamer.safeComponent(request.sourceURL.lastPathComponent, fallback: "Episode")
            return AudioPlayerConfig.join(config.podcastPath, show, file)
        case .audiobook:
            let author = PlayerFileNamer.safeComponent(draft.albumListArtist, fallback: "Unknown Author")
            let book = PlayerFileNamer.safeComponent(draft.album, fallback: "Audiobook")
            let file = PlayerFileNamer.safeComponent(request.sourceURL.lastPathComponent, fallback: "Part")
            return AudioPlayerConfig.join(config.audiobookPath, author, book, discFolder(of: request), file)
        case .music:
            break
        }
        let artist = PlayerFileNamer.safeComponent(draft.albumListArtist, fallback: LibraryTrack.unknownArtist)
        let album = PlayerFileNamer.safeComponent(draft.album, fallback: LibraryTrack.unknownAlbum)
        return AudioPlayerConfig.join(config.musicPath, artist, album, fileName(for: request))
    }

    /// A book's "CD 1" or "Disc 2" folder, kept so the discs' files neither collide nor play out of order.
    private func discFolder(of request: IPodSyncRequest) -> String {
        let folder = request.sourceURL.deletingLastPathComponent().lastPathComponent
        return AudiobookGrouper.isDiscFolderName(folder) ? PlayerFileNamer.safeComponent(folder, fallback: "") : ""
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
