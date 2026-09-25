import Foundation

/// Builds ArtworkDB records, laid out the way iTunes writes them for the iPod with video.
nonisolated enum ArtworkRecordBuilder {
    static let firstImageID: UInt32 = 100
    private static let thumbnailType: UInt16 = 2
    private static let fileNameType: UInt16 = 3
    private static let utf16Marker: UInt32 = 2

    static func emptyDatabase(formats: [ArtworkFormat]) -> ITunesDBRecord {
        let sections = [
            section(.images, list: list("mhli", [])),
            section(.albums, list: list("mhla", [])),
            section(.files, list: list("mhlf", formats.map(fileEntry)))
        ]
        var mhfd = ITunesDBRecordFactory.record("mhfd", headerLength: 0x84, body: .container(sections, trailer: Data()))
        mhfd.set(UInt32(2), at: 0x10)
        mhfd.set(UInt32(sections.count), at: 0x14)
        mhfd.set(firstImageID, at: 0x1C)
        return mhfd
    }

    static func image(id: UInt32, trackDatabaseID: UInt64, thumbnails: [ArtworkThumbnail]) -> ITunesDBRecord {
        let children = thumbnails.map(thumbnailContainer)
        var mhii = ITunesDBRecordFactory.record("mhii", headerLength: 0x98, body: .container(children, trailer: Data()))
        mhii.set(UInt32(children.count), at: 0x0C)
        mhii.set(id, at: 0x10)
        mhii.set(trackDatabaseID, at: 0x14)
        mhii.set(UInt32(1), at: 0x38)
        mhii.set(UInt32(1), at: 0x3C)
        mhii.set(Double.nan.bitPattern, at: 0x48)
        mhii.set(Double.nan.bitPattern, at: 0x50)
        return mhii
    }

    static func fileEntry(_ format: ArtworkFormat) -> ITunesDBRecord {
        var mhif = ITunesDBRecordFactory.record("mhif", headerLength: 0x7C, body: .container([], trailer: Data()))
        mhif.set(format.id, at: 0x10)
        mhif.set(UInt32(format.byteCount), at: 0x14)
        return mhif
    }

    private static func thumbnailContainer(_ thumbnail: ArtworkThumbnail) -> ITunesDBRecord {
        let format = thumbnail.format
        var mhni = ITunesDBRecordFactory.record("mhni", headerLength: 0x4C,
                                                body: .container([fileName(format)], trailer: Data()))
        mhni.set(UInt32(1), at: 0x0C)
        mhni.set(format.id, at: 0x10)
        mhni.set(thumbnail.offset, at: 0x14)
        mhni.set(UInt32(format.byteCount), at: 0x18)
        mhni.set(Int16(clamping: thumbnail.verticalPadding), at: 0x1C)
        mhni.set(Int16(clamping: thumbnail.horizontalPadding), at: 0x1E)
        mhni.set(UInt16(format.height), at: 0x20)
        mhni.set(UInt16(format.width), at: 0x22)
        mhni.set(UInt32(format.byteCount), at: 0x28)
        return mhod(type: thumbnailType, children: [mhni], trailer: Data())
    }

    private static func fileName(_ format: ArtworkFormat) -> ITunesDBRecord {
        let text = ":\(format.fileName)".data(using: .utf16LittleEndian) ?? Data()
        var payload = Data(count: 0x0C)
        payload.write(UInt32(text.count), at: 0x00)
        payload.write(utf16Marker, at: 0x04)
        return mhod(type: fileNameType, children: [], trailer: payload + text)
    }

    private static func mhod(type: UInt16, children: [ITunesDBRecord], trailer: Data) -> ITunesDBRecord {
        var mhod = ITunesDBRecordFactory.record("mhod", headerLength: 0x18, body: .container(children, trailer: trailer))
        mhod.set(type, at: 0x0C)
        return mhod
    }

    private static func section(_ type: ArtworkDBSectionType, list: ITunesDBRecord) -> ITunesDBRecord {
        var mhsd = ITunesDBRecordFactory.record("mhsd", headerLength: 0x60, body: .container([list], trailer: Data()))
        mhsd.set(type.rawValue, at: 0x0C)
        return mhsd
    }

    private static func list(_ tag: String, _ items: [ITunesDBRecord]) -> ITunesDBRecord {
        ITunesDBRecordFactory.record(tag, headerLength: 0x5C, body: .list(items))
    }
}
