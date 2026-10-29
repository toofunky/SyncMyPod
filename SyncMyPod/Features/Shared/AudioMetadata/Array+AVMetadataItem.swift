import AVFoundation

/// Lookups that accept iTunes (.m4a), ID3 (.mp3) and Vorbis comment (.flac) identifiers, returning the first
/// that's present.
nonisolated extension [AVMetadataItem] {
    var coverArt: AVMetadataItem? {
        firstItem(matching: [.iTunesMetadataCoverArt, .id3MetadataAttachedPicture, .vorbisPicture])
    }

    var lyrics: AVMetadataItem? {
        firstItem(matching: [.iTunesMetadataLyrics, .id3MetadataUnsynchronizedLyric, .vorbisLyrics,
                             .vorbisUnsyncedLyrics])
    }

    func firstItem(matching identifiers: [AVMetadataIdentifier]) -> AVMetadataItem? {
        identifiers.lazy
            .compactMap { AVMetadataItem.metadataItems(from: self, filteredByIdentifier: $0).first }
            .first
    }
}
