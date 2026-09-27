import Foundation

/// Builds an `mhit` for an AAC, Apple Lossless or MP3 file. Offsets follow libgpod's documented layout.
nonisolated struct TrackRecordBuilder {
    static let minimumHeaderLength = 0x184
    private static let audioMediaType: UInt32 = 1
    private static let hasArtwork: UInt8 = 1
    private static let noArtwork: UInt8 = 2
    private static let albumIDOffset = 0x120
    private static let artworkIDOffset = 0x160
    private static let dateAddedOffset = 0x68

    let headerLength: Int

    func build(_ draft: ITunesTrackDraft, id: UInt32, databaseID: UInt64, albumID: UInt32) -> ITunesDBRecord {
        let strings = Self.stringRecords(for: draft)
        var mhit = ITunesDBRecordFactory.record("mhit", headerLength: headerLength,
                                                body: .container(strings, trailer: Data()))
        mhit.set(UInt32(strings.count), at: 0x0C)
        writeIdentity(into: &mhit, id: id, databaseID: databaseID, albumID: albumID)
        mhit.set(ITunesTimestamp.seconds(from: draft.dateAdded), at: Self.dateAddedOffset)
        apply(draft, to: &mhit, includingArtwork: true)
        return mhit
    }

    /// Writes the draft's tags, format and optionally artwork link, leaving IDs, date added and play statistics.
    func apply(_ draft: ITunesTrackDraft, to mhit: inout ITunesDBRecord, includingArtwork: Bool) {
        writeTags(into: &mhit, from: draft)
        writeFormat(into: &mhit, from: draft)
        if includingArtwork { writeArtwork(into: &mhit, draft.artwork) }
    }

    static func stringRecords(for draft: ITunesTrackDraft) -> [ITunesDBRecord] {
        let fields: [(ITunesStringField, String)] = [
            (.title, draft.title), (.location, draft.location), (.album, draft.album),
            (.artist, draft.artist), (.genre, draft.genre), (.fileType, draft.codec.iTunesKind),
            (.albumArtist, draft.albumArtist), (.composer, draft.composer)
        ]
        return fields.filter { !$0.1.isEmpty }
            .map { ITunesDBRecordFactory.string(type: $0.0.rawValue, value: $0.1) }
    }

    private func writeIdentity(into mhit: inout ITunesDBRecord, id: UInt32, databaseID: UInt64, albumID: UInt32) {
        mhit.set(id, at: 0x10)
        mhit.set(UInt32(1), at: 0x14)
        mhit.set(databaseID, at: 0x70)
        mhit.set(databaseID, at: 0xA8)
        mhit.set(Self.audioMediaType, at: 0xD0)
        mhit.set(albumID, at: Self.albumIDOffset)
    }

    private func writeTags(into mhit: inout ITunesDBRecord, from draft: ITunesTrackDraft) {
        mhit.set(ITunesTimestamp.seconds(from: draft.lastModified), at: 0x20)
        mhit.set(UInt32(clamping: Int((draft.duration * 1_000).rounded())), at: 0x28)
        mhit.set(UInt32(clamping: draft.trackNumber), at: 0x2C)
        mhit.set(UInt32(clamping: draft.trackCount), at: 0x30)
        mhit.set(UInt32(clamping: draft.year), at: 0x34)
        mhit.set(UInt32(clamping: draft.discNumber), at: 0x5C)
        mhit.set(UInt32(clamping: draft.discCount), at: 0x60)
    }

    /// Sets both the legacy count/size fields and the iTunes 7.1+ `mhii` link, so either firmware style finds it.
    private func writeArtwork(into mhit: inout ITunesDBRecord, _ artwork: ITunesTrackArtwork?) {
        guard let artwork else {
            mhit.set(UInt16(0), at: 0x7C)
            mhit.set(UInt32(0), at: 0x80)
            mhit.set(Self.noArtwork, at: 0xA4)
            mhit.set(UInt32(0), at: Self.artworkIDOffset)
            return
        }
        mhit.set(UInt16(1), at: 0x7C)
        mhit.set(UInt32(clamping: artwork.sourceByteCount), at: 0x80)
        mhit.set(Self.hasArtwork, at: 0xA4)
        mhit.set(artwork.imageID, at: Self.artworkIDOffset)
    }

    private func writeFormat(into mhit: inout ITunesDBRecord, from draft: ITunesTrackDraft) {
        mhit.set(draft.codec.iTunesFileType, at: 0x18)
        mhit.set(UInt32(clamping: draft.fileSize), at: 0x24)
        mhit.set(UInt32(clamping: draft.bitrate), at: 0x38)
        mhit.set(UInt32(clamping: draft.sampleRate) << 16, at: 0x3C)
        mhit.set(UInt16.max, at: 0x7E)
        mhit.set(Float(draft.sampleRate).bitPattern, at: 0x88)
        mhit.set(draft.codec.iTunesFormatMarker, at: 0x90)
    }
}
