import AVFoundation

nonisolated struct AudioTagReader {
    let items: [AVMetadataItem]

    func tags() async -> AudioTags {
        AudioTags(
            title: await string([.iTunesMetadataSongName, .id3MetadataTitleDescription, .vorbisTitle]),
            artist: await string([.iTunesMetadataArtist, .id3MetadataLeadPerformer, .vorbisArtist]),
            album: await string([.iTunesMetadataAlbum, .id3MetadataAlbumTitle, .vorbisAlbum]),
            albumArtist: await string([.iTunesMetadataAlbumArtist, .id3MetadataBand, .vorbisAlbumArtist,
                                       .vorbisAlbumArtistSpaced]),
            composer: await string([.iTunesMetadataComposer, .id3MetadataComposer, .vorbisComposer]),
            genre: await string([.iTunesMetadataUserGenre, .id3MetadataContentType, .vorbisGenre]),
            year: await string([.iTunesMetadataReleaseDate, .id3MetadataRecordingTime, .id3MetadataYear,
                                .vorbisDate, .vorbisYear])
                .flatMap { Int($0.prefix(4)) },
            track: await numberPair([.iTunesMetadataTrackNumber, .id3MetadataTrackNumber, .vorbisTrackNumber],
                                    totals: [.vorbisTrackTotal, .vorbisTotalTracks]),
            disc: await numberPair([.iTunesMetadataDiscNumber, .id3MetadataPartOfASet, .vorbisDiscNumber],
                                   totals: [.vorbisDiscTotal, .vorbisTotalDiscs]),
            sortTitle: await string([.iTunesSortName, .id3MetadataTitleSortOrder, .vorbisSortTitle]),
            sortArtist: await string([.iTunesSortArtist, .id3MetadataPerformerSortOrder, .vorbisSortArtist]),
            sortAlbumArtist: await string([.iTunesSortAlbumArtist, .id3SortAlbumArtist, .vorbisSortAlbumArtist]),
            sortAlbum: await string([.iTunesSortAlbum, .id3MetadataAlbumSortOrder, .vorbisSortAlbum]),
            sortComposer: await string([.iTunesSortComposer, .id3SortComposer, .vorbisSortComposer])
        )
    }

    private func string(_ identifiers: [AVMetadataIdentifier]) async -> String? {
        guard let value = try? await items.firstItem(matching: identifiers)?.load(.stringValue) else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// `totals` are Vorbis comments' separate count fields, read when the number has no `"/count"`.
    private func numberPair(_ identifiers: [AVMetadataIdentifier],
                            totals: [AVMetadataIdentifier]) async -> TagNumberPair {
        guard let item = items.firstItem(matching: identifiers) else { return TagNumberPair() }
        guard item.keySpace != .iTunes else {
            guard let data = try? await item.load(.dataValue) else { return TagNumberPair() }
            return TagNumberPair(atomData: data)
        }
        guard let text = try? await item.load(.stringValue) else { return TagNumberPair() }
        var pair = TagNumberPair(text: text)
        if pair.count == 0, let total = await string(totals) { pair.count = Int(total) ?? 0 }
        return pair
    }
}
