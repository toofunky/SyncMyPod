import Foundation

nonisolated extension TrackTags {
    var artistDiffersFromAlbumArtist: Bool {
        let artist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let albumArtist = albumArtist.trimmingCharacters(in: .whitespacesAndNewlines)
        return !artist.isEmpty && !albumArtist.isEmpty && artist.caseInsensitiveCompare(albumArtist) != .orderedSame
    }

    /// Moves a guest artist into the title, e.g. "Die With A Smile — Bruno Mars" by Lady Gaga, so the iPod
    /// lists the song under its album artist.
    func preservingAlbumArtist() -> TrackTags {
        guard artistDiffersFromAlbumArtist else { return self }
        var tags = self
        tags.title = "\(title) — \(artist)"
        tags.artist = albumArtist
        if !sortTitle.isEmpty { tags.sortTitle = "\(sortTitle) — \(artist)" }
        tags.sortArtist = sortAlbumArtist
        return tags
    }
}
