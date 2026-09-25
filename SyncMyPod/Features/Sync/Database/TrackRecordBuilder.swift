import Foundation

/// Builds an `mhit` for an AAC file. Offsets follow libgpod's documented layout.
nonisolated struct TrackRecordBuilder {
    static let minimumHeaderLength = 0x184
    private static let m4aFileType: UInt32 = 0x4D34_4120
    private static let audioMediaType: UInt32 = 1
    private static let noArtwork: UInt8 = 2
    private static let aacFormatMarker: UInt16 = 0x0033
    private static let albumIDOffset = 0x120

    let headerLength: Int

    func build(_ draft: ITunesTrackDraft, id: UInt32, databaseID: UInt64, albumID: UInt32) -> ITunesDBRecord {
        let strings = stringRecords(for: draft)
        var mhit = ITunesDBRecordFactory.record("mhit", headerLength: headerLength,
                                                body: .container(strings, trailer: Data()))
        mhit.set(UInt32(strings.count), at: 0x0C)
        writeIdentity(into: &mhit, id: id, databaseID: databaseID, albumID: albumID)
        writeTags(into: &mhit, from: draft)
        writeFormat(into: &mhit, from: draft)
        return mhit
    }

    private func stringRecords(for draft: ITunesTrackDraft) -> [ITunesDBRecord] {
        let fields: [(ITunesStringField, String)] = [
            (.title, draft.title), (.location, draft.location), (.album, draft.album),
            (.artist, draft.artist), (.genre, draft.genre), (.fileType, "AAC audio file"),
            (.albumArtist, draft.albumArtist)
        ]
        return fields.filter { !$0.1.isEmpty }
            .map { ITunesDBRecordFactory.string(type: $0.0.rawValue, value: $0.1) }
    }

    private func writeIdentity(into mhit: inout ITunesDBRecord, id: UInt32, databaseID: UInt64, albumID: UInt32) {
        mhit.set(id, at: 0x10)
        mhit.set(UInt32(1), at: 0x14)
        mhit.set(databaseID, at: 0x70)
        mhit.set(Self.noArtwork, at: 0xA4)
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
        mhit.set(ITunesTimestamp.seconds(from: draft.dateAdded), at: 0x68)
    }

    private func writeFormat(into mhit: inout ITunesDBRecord, from draft: ITunesTrackDraft) {
        mhit.set(Self.m4aFileType, at: 0x18)
        mhit.set(UInt32(clamping: draft.fileSize), at: 0x24)
        mhit.set(UInt32(clamping: draft.bitrate), at: 0x38)
        mhit.set(UInt32(clamping: draft.sampleRate) << 16, at: 0x3C)
        mhit.set(UInt16.max, at: 0x7E)
        mhit.set(Float(draft.sampleRate).bitPattern, at: 0x88)
        mhit.set(Self.aacFormatMarker, at: 0x90)
    }
}
