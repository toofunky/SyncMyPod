import AVFoundation

nonisolated struct AudioTagReader {
    let items: [AVMetadataItem]

    func tags() async -> AudioTags {
        AudioTags(
            title: await string([.iTunesMetadataSongName, .id3MetadataTitleDescription]),
            artist: await string([.iTunesMetadataArtist, .id3MetadataLeadPerformer]),
            album: await string([.iTunesMetadataAlbum, .id3MetadataAlbumTitle]),
            albumArtist: await string([.iTunesMetadataAlbumArtist, .id3MetadataBand]),
            composer: await string([.iTunesMetadataComposer, .id3MetadataComposer]),
            genre: await string([.iTunesMetadataUserGenre, .id3MetadataContentType]),
            year: await string([.iTunesMetadataReleaseDate, .id3MetadataRecordingTime, .id3MetadataYear])
                .flatMap { Int($0.prefix(4)) },
            track: await numberPair([.iTunesMetadataTrackNumber, .id3MetadataTrackNumber]),
            disc: await numberPair([.iTunesMetadataDiscNumber, .id3MetadataPartOfASet])
        )
    }

    private func string(_ identifiers: [AVMetadataIdentifier]) async -> String? {
        guard let value = try? await items.firstItem(matching: identifiers)?.load(.stringValue) else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func numberPair(_ identifiers: [AVMetadataIdentifier]) async -> TagNumberPair {
        guard let item = items.firstItem(matching: identifiers) else { return TagNumberPair() }
        if item.keySpace == .id3 {
            guard let text = try? await item.load(.stringValue) else { return TagNumberPair() }
            return TagNumberPair(text: text)
        }
        guard let data = try? await item.load(.dataValue) else { return TagNumberPair() }
        return TagNumberPair(atomData: data)
    }
}
