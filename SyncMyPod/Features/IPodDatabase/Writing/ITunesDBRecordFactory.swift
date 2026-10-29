import Foundation

nonisolated enum ITunesDBRecordFactory {
    private static let mhodHeaderLength = 0x18
    private static let utf16Encoding: UInt32 = 1

    static func record(_ tag: String, headerLength: Int, body: ITunesDBRecordBody) -> ITunesDBRecord {
        var header = Data(count: headerLength)
        header.replaceSubrange(0..<4, with: Data(tag.utf8))
        header.write(UInt32(headerLength), at: 0x04)
        return ITunesDBRecord(header: header, body: body)
    }

    /// A UTF-16 string `mhod`, laid out the way iTunes writes it.
    static func string(type: UInt32, value: String) -> ITunesDBRecord {
        let text = value.data(using: .utf16LittleEndian) ?? Data()
        var prefix = Data(count: 0x10)
        prefix.write(utf16Encoding, at: 0x00)
        prefix.write(UInt32(text.count), at: 0x04)
        prefix.write(UInt32(1), at: 0x08)
        return mhod(type: type, payload: prefix + text)
    }

    static func mhod(type: UInt32, payload: Data) -> ITunesDBRecord {
        var mhod = record("mhod", headerLength: mhodHeaderLength, body: .opaque(payload))
        mhod.set(type, at: 0x0C)
        return mhod
    }
}
