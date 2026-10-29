import Foundation

/// Reads the ID3v2 tag at `offset`: the start of an MP3, or an AIFF or WAV file's ID3 chunk. Frames of a
/// v2.2 tag use a different layout and are dropped; files without a tag come back as an empty v2.3 tag.
nonisolated enum ID3TagParser {
    private static let unsynchronisationFlag: UInt8 = 0x80
    private static let extendedHeaderFlag: UInt8 = 0x40
    private static let footerFlag: UInt8 = 0x10

    static func parse(_ handle: FileHandle, at offset: UInt64 = 0) throws -> ID3Tag {
        try handle.seek(toOffset: offset)
        let header = try handle.read(upToCount: ID3Tag.headerSize) ?? Data()
        guard header.count == ID3Tag.headerSize, header.prefix(3) == Data("ID3".utf8) else { return ID3Tag() }
        let major = header[3], flags = header[5]
        let bodyLength = Synchsafe.decode(header, at: 6)
        guard let body = try handle.read(upToCount: bodyLength), body.count == bodyLength else {
            throw TagWriterError.unexpectedEndOfFile
        }
        let footerLength = major >= 4 && flags & footerFlag != 0 ? ID3Tag.headerSize : 0
        let length = ID3Tag.headerSize + bodyLength + footerLength
        guard major == 3 || major == 4 else { return ID3Tag(existingLength: length) }
        let frames = frames(in: frameData(body, major: major, flags: flags), major: major)
        return ID3Tag(majorVersion: major, frames: frames, existingLength: length)
    }

    /// Undoes v2.3's whole-tag unsynchronisation (v2.4 flags it per frame) and skips any extended header.
    private static func frameData(_ body: Data, major: UInt8, flags: UInt8) -> Data {
        var data = major == 3 && flags & unsynchronisationFlag != 0 ? resynchronised(body) : Data(body)
        guard flags & extendedHeaderFlag != 0 else { return data }
        let length = major >= 4 ? Synchsafe.decode(data, at: 0) : Int(data.readBigEndian(UInt32.self, at: 0)) + 4
        data.removeFirst(min(length, data.count))
        return data
    }

    private static func frames(in data: Data, major: UInt8) -> [ID3Frame] {
        var frames: [ID3Frame] = []
        var offset = 0
        while offset + ID3Frame.headerSize <= data.count, data[offset] != 0 {
            let size = major >= 4 ? Synchsafe.decode(data, at: offset + 4)
                                  : Int(data.readBigEndian(UInt32.self, at: offset + 4))
            let start = offset + ID3Frame.headerSize
            guard start + size <= data.count else { break }
            frames.append(ID3Frame(id: FourCC(rawValue: data.readBigEndian(UInt32.self, at: offset)),
                                   flags: data.readBigEndian(UInt16.self, at: offset + 8),
                                   body: data.subdata(in: start..<start + size)))
            offset = start + size
        }
        return frames
    }

    private static func resynchronised(_ data: Data) -> Data {
        var result = Data(capacity: data.count)
        var afterSync = false
        for byte in data {
            if !(afterSync && byte == 0x00) { result.append(byte) }
            afterSync = byte == 0xFF
        }
        return result
    }
}
