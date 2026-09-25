import AVFoundation

nonisolated struct AudioTagReader {
    let items: [AVMetadataItem]

    func tags() async -> AudioTags {
        AudioTags(
            title: await string(.iTunesMetadataSongName),
            artist: await string(.iTunesMetadataArtist),
            album: await string(.iTunesMetadataAlbum),
            albumArtist: await string(.iTunesMetadataAlbumArtist),
            genre: await string(.iTunesMetadataUserGenre),
            year: await string(.iTunesMetadataReleaseDate).flatMap { Int($0.prefix(4)) },
            track: await numberPair(.iTunesMetadataTrackNumber),
            disc: await numberPair(.iTunesMetadataDiscNumber)
        )
    }

    private func item(_ identifier: AVMetadataIdentifier) -> AVMetadataItem? {
        AVMetadataItem.metadataItems(from: items, filteredByIdentifier: identifier).first
    }

    private func string(_ identifier: AVMetadataIdentifier) async -> String? {
        guard let value = try? await item(identifier)?.load(.stringValue) else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func numberPair(_ identifier: AVMetadataIdentifier) async -> TagNumberPair {
        guard let data = try? await item(identifier)?.load(.dataValue) else { return TagNumberPair() }
        return TagNumberPair(atomData: data)
    }
}
