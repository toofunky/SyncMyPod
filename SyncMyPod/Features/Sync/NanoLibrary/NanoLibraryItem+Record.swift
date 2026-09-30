import Foundation

nonisolated extension NanoLibraryItem {
    /// Field offsets were matched against a database iTunes wrote to a nano 7G.
    init(mhit: ITunesDBRecord) {
        let strings = mhit.children.compactMap { mhod -> (ITunesStringField, String)? in
            guard let field = ITunesStringField(rawValue: mhod.recordType),
                  let value = mhit.string(ofType: field.rawValue) else { return nil }
            return (field, value)
        }
        self.init(
            pid: mhit.uint64(at: 0x70), strings: Dictionary(strings, uniquingKeysWith: { first, _ in first }),
            mediaType: mhit.uint32(at: 0xD0), isCompilation: mhit.uint8(at: 0x1E) != 0,
            rating: Int(mhit.uint8(at: 0x1F)), year: Int(mhit.uint32(at: 0x34)),
            durationMS: Int(mhit.uint32(at: 0x28)), trackNumber: Int(mhit.uint32(at: 0x2C)),
            trackCount: Int(mhit.uint32(at: 0x30)), discNumber: Int(mhit.uint32(at: 0x5C)),
            discCount: Int(mhit.uint32(at: 0x60)), bpm: Int(mhit.header.read(UInt16.self, at: 0x7A)),
            bitrate: Int(mhit.uint32(at: 0x38)), sampleRate: Int(mhit.header.read(UInt16.self, at: 0x3E)),
            fileSize: Int(mhit.uint32(at: 0x24)), fileTypeCode: mhit.uint32(at: 0x18),
            playCount: Int(mhit.uint32(at: 0x50)), skipCount: Int(mhit.uint32(at: 0x98)),
            dateLastSkipped: mhit.uint32(at: 0xA0), bookmarkMS: Int(mhit.uint32(at: 0x6C)),
            dateModified: mhit.uint32(at: 0x20), dateLastPlayed: mhit.uint32(at: 0x58),
            dateAdded: mhit.uint32(at: 0x68), dateReleased: mhit.uint32(at: 0x8C),
            volumeNormalization: Int(mhit.uint32(at: 0x4C)), sampleCount: UInt64(mhit.uint32(at: 0xBC)),
            encoderDelay: Int(mhit.uint32(at: 0xB8)), encoderDrain: Int(mhit.uint32(at: 0xC8)),
            lastFrameResync: Int(mhit.uint32(at: 0xF8)), artworkID: mhit.uint32(at: 0x160),
            albumID: mhit.uint32(at: 0x120), artistID: mhit.uint32(at: 0x1E0)
        )
    }
}
