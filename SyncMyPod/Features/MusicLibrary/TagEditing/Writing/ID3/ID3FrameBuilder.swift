import Foundation

nonisolated enum ID3FrameBuilder {
    private static let utf16Encoding: UInt8 = 1
    private static let latin1Encoding: UInt8 = 0
    private static let frontCoverPictureType: UInt8 = 3

    /// UTF-16 with a byte-order mark, which both v2.3 and v2.4 readers understand.
    static func text(_ id: FourCC, _ value: String) -> ID3Frame {
        ID3Frame(id: id, body: Data([utf16Encoding]) + utf16(value) + [0, 0])
    }

    /// Encoding, language, an empty description and the text, which runs to the end of the frame.
    static func lyrics(_ value: String) -> ID3Frame {
        ID3Frame(id: .id3Lyrics, body: Data([utf16Encoding]) + Data("eng".utf8) + utf16("") + [0, 0] + utf16(value))
    }

    /// `"3/12"`, or `"3"` when the count is unknown.
    static func numberPair(_ id: FourCC, _ pair: TagNumberPair) -> ID3Frame {
        text(id, pair.count > 0 ? "\(pair.number)/\(pair.count)" : "\(pair.number)")
    }

    static func frontCover(_ image: Data, type: ArtworkImageType) -> ID3Frame {
        var body = Data([latin1Encoding])
        body.append(Data(type.mimeType.utf8))
        body.append(contentsOf: [0, frontCoverPictureType, 0])
        body.append(image)
        return ID3Frame(id: .id3Picture, body: body)
    }

    /// Little-endian UTF-16 behind a byte-order mark, unterminated.
    private static func utf16(_ value: String) -> Data {
        var data = Data([0xFF, 0xFE])
        value.utf16.forEach { data.append(contentsOf: [UInt8($0 & 0xFF), UInt8($0 >> 8)]) }
        return data
    }
}
