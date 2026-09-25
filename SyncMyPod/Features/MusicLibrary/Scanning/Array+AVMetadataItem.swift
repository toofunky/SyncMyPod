import AVFoundation

/// Lookups that accept both iTunes (.m4a) and ID3 (.mp3) identifiers, returning the first that's present.
nonisolated extension [AVMetadataItem] {
    var coverArt: AVMetadataItem? { firstItem(matching: [.iTunesMetadataCoverArt, .id3MetadataAttachedPicture]) }

    func firstItem(matching identifiers: [AVMetadataIdentifier]) -> AVMetadataItem? {
        identifiers.lazy
            .compactMap { AVMetadataItem.metadataItems(from: self, filteredByIdentifier: $0).first }
            .first
    }
}
