import Foundation

extension LibraryTrack {
    /// `preservingAlbumArtist` and `embeddingLyricsSidecar` change only the copy on the iPod, never the file.
    /// A lyric file is embedded only in songs without lyrics of their own.
    func syncRequest(preservingAlbumArtist: Bool, embeddingLyricsSidecar: Bool = false) -> IPodSyncRequest {
        let preserves = preservingAlbumArtist && draft.artistDiffersFromAlbumArtist
        let embeds = embeddingLyricsSidecar && hasLyrics && !hasEmbeddedLyrics
        var draft = preserves ? draft.preservingAlbumArtist() : draft
        draft.hasLyrics = hasEmbeddedLyrics || embeds
        return IPodSyncRequest(sourceURL: URL(filePath: filePath), draft: draft,
                               source: syncSource(preservedAlbumArtist: preserves, embeddedLyricsSidecar: embeds),
                               embedsLyricsSidecar: embeds)
    }

    private func syncSource(preservedAlbumArtist: Bool, embeddedLyricsSidecar: Bool) -> SyncSource? {
        guard scanVersion == Self.currentScanVersion else { return nil }
        return SyncSource(fileSize: fileSize, modificationDate: modificationDate,
                          artworkFingerprint: artworkFingerprint,
                          preservedAlbumArtist: preservedAlbumArtist ? true : nil,
                          hasLyrics: hasEmbeddedLyrics || embeddedLyricsSidecar ? true : nil,
                          lyricsSidecarDate: embeddedLyricsSidecar ? lyricsFileDate : nil)
    }

    private var draft: ITunesTrackDraft {
        ITunesTrackDraft(title: title, artist: artist, album: album, albumArtist: albumArtist,
                         composer: composer, genre: genre,
                         fileSize: fileSize, duration: duration, trackNumber: trackNumber,
                         trackCount: trackCount, discNumber: discNumber, discCount: discCount, year: year,
                         bitrate: bitrate, sampleRate: sampleRate, dateAdded: .now,
                         lastModified: modificationDate, codec: codec,
                         sortTitle: title.iPodSortValue(tagged: sortTitleTag),
                         sortArtist: artist.iPodSortValue(tagged: sortArtistTag),
                         sortAlbumArtist: albumArtist.iPodSortValue(tagged: sortAlbumArtistTag),
                         sortAlbum: album.iPodSortValue(tagged: sortAlbumTag),
                         sortComposer: composer.iPodSortValue(tagged: sortComposerTag))
    }
}
