import Foundation

nonisolated extension ITunesTrackDraft {
    var artistDiffersFromAlbumArtist: Bool {
        let artist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let albumArtist = albumArtist.trimmingCharacters(in: .whitespacesAndNewlines)
        return !artist.isEmpty && !albumArtist.isEmpty && artist.caseInsensitiveCompare(albumArtist) != .orderedSame
    }

    /// Moves a guest artist into the title, e.g. "Die With A Smile — Bruno Mars" by Lady Gaga, so the iPod
    /// lists the song under its album artist.
    func preservingAlbumArtist() -> ITunesTrackDraft {
        guard artistDiffersFromAlbumArtist else { return self }
        var draft = self
        draft.title = "\(title) — \(artist)"
        draft.artist = albumArtist
        if !sortTitle.isEmpty { draft.sortTitle = "\(sortTitle) — \(artist)" }
        draft.sortArtist = sortAlbumArtist
        return draft
    }
}
