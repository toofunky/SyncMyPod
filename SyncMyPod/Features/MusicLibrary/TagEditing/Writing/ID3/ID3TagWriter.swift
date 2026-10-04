import Foundation

/// Updates the ID3v2 tag at the start of an MP3, keeping the tag's version (v2.3 for new tags) and
/// every frame it doesn't change. The tag is overwritten in place when it fits in the old one's padding.
nonisolated struct ID3TagWriter {
    private static let padding = 2_048

    func write(_ changes: TagChanges, to url: URL) throws {
        var tag = try readTag(at: url)
        apply(changes, to: &tag)
        let fitted = tag.serialized(minimumLength: tag.existingLength)
        let data = fitted.count == tag.existingLength
            ? fitted : tag.serialized(minimumLength: fitted.count + Self.padding)
        try FileRegionReplacer(url: url).replace(0..<tag.existingLength, with: data)
    }

    private func readTag(at url: URL) throws -> ID3Tag {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        return try ID3TagParser.parse(handle)
    }

    func apply(_ changes: TagChanges, to tag: inout ID3Tag) {
        let yearID: FourCC = tag.majorVersion >= 4 ? .id3RecordingTime : .id3Year
        let texts: [(FourCC, String?)] = [
            (.id3Title, changes.title), (.id3Artist, changes.artist), (.id3Album, changes.album),
            (.id3AlbumArtist, changes.albumArtist), (.id3Composer, changes.composer), (.id3Genre, changes.genre),
            (yearID, changes.year.map { $0 > 0 ? String($0) : "" }),
            (.id3SortTitle, changes.sortTitle), (.id3SortArtist, changes.sortArtist),
            (.id3SortAlbumArtist, changes.sortAlbumArtist), (.id3SortAlbum, changes.sortAlbum),
            (.id3SortComposer, changes.sortComposer),
        ]
        for case let (id, value?) in texts {
            let replaced: Set<FourCC> = id == yearID ? [.id3Year, .id3RecordingTime] : [id]
            set(replaced, value.isEmpty ? nil : ID3FrameBuilder.text(id, value), in: &tag.frames)
        }
        for case let (id, pair?) in [(FourCC.id3Track, changes.track), (.id3Disc, changes.disc)] {
            set([id], pair.number > 0 ? ID3FrameBuilder.numberPair(id, pair) : nil, in: &tag.frames)
        }
        applyArtwork(changes.artwork, to: &tag.frames)
    }

    private func applyArtwork(_ change: ArtworkChange, to frames: inout [ID3Frame]) {
        switch change {
        case .keep: return
        case .remove: set([.id3Picture], nil, in: &frames)
        case .replace(let image):
            guard let type = ArtworkImageType(data: image) else { return }
            set([.id3Picture], ID3FrameBuilder.frontCover(image, type: type), in: &frames)
        }
    }

    /// Replaces every frame with one of `ids` by `frame` where the first stood; `nil` removes them.
    private func set(_ ids: Set<FourCC>, _ frame: ID3Frame?, in frames: inout [ID3Frame]) {
        let index = frames.firstIndex { ids.contains($0.id) }
        frames.removeAll { ids.contains($0.id) }
        guard let frame else { return }
        frames.insert(frame, at: min(index ?? frames.count, frames.count))
    }
}
