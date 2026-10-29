import Foundation

nonisolated extension SyncRequest {
    /// The tags to rewrite in a player's copy when its album artist is preserved, or `nil` to copy it as is.
    /// Players read tags from the file, so the copy itself carries the artist and title an iPod would show.
    var playerTagChanges: TagChanges? {
        guard source?.preservedAlbumArtist == true else { return nil }
        return TagChanges(title: tags.title, artist: tags.artist,
                          sortTitle: tags.sortTitle.isEmpty ? nil : tags.sortTitle, sortArtist: tags.sortArtist)
    }

    /// Records the size the copy's embedded artwork is scaled to fit, so changing it updates the copies.
    /// Songs without artwork aren't affected, so they're never copied again for it.
    func resizingArtwork(to pixelLimit: Int?) -> SyncRequest {
        guard var source, source.artworkFingerprint != nil else { return self }
        source.artworkPixelLimit = pixelLimit
        return SyncRequest(sourceURL: sourceURL, tags: tags, source: source,
                               embedsLyricsSidecar: embedsLyricsSidecar, kind: kind,
                               coverImageURL: coverImageURL)
    }
}
