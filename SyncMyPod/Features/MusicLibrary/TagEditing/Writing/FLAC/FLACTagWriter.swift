import Foundation

/// Updates the Vorbis comment and pictures of a FLAC file, keeping every comment and block it doesn't change.
/// The metadata is overwritten in place when it fits in the old metadata and its padding.
nonisolated struct FLACTagWriter {
    private static let padding = 4_096

    func write(_ changes: TagChanges, to url: URL) throws {
        var metadata = try readMetadata(at: url)
        var comment = metadata.vorbisComment
        apply(changes, to: &comment)
        metadata.setVorbisComment(comment)
        applyArtwork(changes.artwork, to: &metadata)
        let fitted = metadata.serialized(minimumLength: metadata.existingLength)
        let data = fitted.count == metadata.existingLength
            ? fitted : metadata.serialized(minimumLength: fitted.count + Self.padding)
        try FileRegionReplacer(url: url).replace(0..<metadata.existingLength, with: data)
    }

    private func readMetadata(at url: URL) throws -> FLACMetadata {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        return try FLACMetadataParser.parse(handle)
    }

    private func apply(_ changes: TagChanges, to comment: inout VorbisComment) {
        let texts: [([String], String?)] = [
            (["TITLE"], changes.title), (["ARTIST"], changes.artist), (["ALBUM"], changes.album),
            (["ALBUMARTIST", "ALBUM ARTIST"], changes.albumArtist), (["COMPOSER"], changes.composer),
            (["GENRE"], changes.genre), (["DATE", "YEAR"], changes.year.map { $0 > 0 ? String($0) : "" }),
            (["TITLESORT"], changes.sortTitle), (["ARTISTSORT"], changes.sortArtist),
            (["ALBUMARTISTSORT"], changes.sortAlbumArtist), (["ALBUMSORT"], changes.sortAlbum),
            (["COMPOSERSORT"], changes.sortComposer),
        ]
        for case let (fields, value?) in texts { comment.set(fields, to: value) }
        if let track = changes.track {
            set(track, number: "TRACKNUMBER", totals: ["TRACKTOTAL", "TOTALTRACKS"], in: &comment)
        }
        if let disc = changes.disc {
            set(disc, number: "DISCNUMBER", totals: ["DISCTOTAL", "TOTALDISCS"], in: &comment)
        }
    }

    /// Writes the count to its own field, as most taggers do, rather than as `"3/12"`.
    private func set(_ pair: TagNumberPair, number: String, totals: [String], in comment: inout VorbisComment) {
        comment.set([number], to: pair.number > 0 ? String(pair.number) : nil)
        comment.set(totals, to: pair.number > 0 && pair.count > 0 ? String(pair.count) : nil)
    }

    private func applyArtwork(_ change: ArtworkChange, to metadata: inout FLACMetadata) {
        switch change {
        case .keep: return
        case .remove: metadata.replaceBlocks(ofType: FLACMetadataBlock.picture, with: [])
        case .replace(let image):
            guard let type = ArtworkImageType(data: image) else { return }
            metadata.replaceBlocks(ofType: FLACMetadataBlock.picture,
                                   with: [FLACPictureBuilder.frontCover(image, type: type)])
        }
    }
}
