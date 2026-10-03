import Foundation

nonisolated extension IPodSyncRequest {
    /// The tags to rewrite in a player's copy when its album artist is preserved, or `nil` to copy it as is.
    /// Players read tags from the file, so the copy itself carries the artist and title an iPod would show.
    var playerTagChanges: TagChanges? {
        guard source?.preservedAlbumArtist == true else { return nil }
        return TagChanges(title: draft.title, artist: draft.artist,
                          sortTitle: draft.sortTitle.isEmpty ? nil : draft.sortTitle, sortArtist: draft.sortArtist)
    }
}
