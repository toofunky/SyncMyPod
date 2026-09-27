import Foundation

extension LibraryTrack {
    /// `preservingAlbumArtist` changes only the tags written to the iPod, never the file.
    func syncRequest(preservingAlbumArtist: Bool) -> IPodSyncRequest {
        let preserves = preservingAlbumArtist && draft.artistDiffersFromAlbumArtist
        return IPodSyncRequest(sourceURL: URL(filePath: filePath),
                               draft: preserves ? draft.preservingAlbumArtist() : draft,
                               source: syncSource(preservedAlbumArtist: preserves))
    }

    private func syncSource(preservedAlbumArtist: Bool) -> SyncSource? {
        guard scanVersion == Self.currentScanVersion else { return nil }
        return SyncSource(fileSize: fileSize, modificationDate: modificationDate,
                          artworkFingerprint: artworkFingerprint,
                          preservedAlbumArtist: preservedAlbumArtist ? true : nil)
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
