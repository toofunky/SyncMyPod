import Foundation

/// Builds iTunes `ilst` items: an atom named for the tag, holding one `data` atom.
nonisolated enum ILSTItemBuilder {
    private static let utf8Type: UInt32 = 1
    private static let implicitType: UInt32 = 0

    static func text(_ type: FourCC, _ value: String) -> MP4Box {
        item(type, dataType: utf8Type, value: Data(value.utf8))
    }

    /// `trkn` carries two trailing reserved bytes that `disk` doesn't.
    static func numberPair(_ type: FourCC, _ pair: TagNumberPair) -> MP4Box {
        var value = Data(count: 2)
        value.appendBigEndian(UInt16(clamping: pair.number))
        value.appendBigEndian(UInt16(clamping: pair.count))
        if type == .trackNumber { value.append(Data(count: 2)) }
        return item(type, dataType: implicitType, value: value)
    }

    static func coverArt(_ image: Data, type: ArtworkImageType) -> MP4Box {
        item(.coverArt, dataType: type.mp4DataType, value: image)
    }

    private static func item(_ type: FourCC, dataType: UInt32, value: Data) -> MP4Box {
        var payload = Data()
        payload.appendBigEndian(dataType)
        payload.appendBigEndian(UInt32(0))
        payload.append(value)
        return MP4Box(type: type, children: [MP4Box(type: .data, payload: payload)])
    }
}
