import Foundation

/// ID3's 28-bit integers stored seven bits per byte so they never look like an MPEG sync word.
nonisolated enum Synchsafe {
    static func decode(_ data: Data, at offset: Int) -> Int {
        (0..<4).reduce(0) { $0 << 7 | Int(data.readBigEndian(UInt8.self, at: offset + $1) & 0x7F) }
    }

    static func encode(_ value: Int) -> Data {
        Data([21, 14, 7, 0].map { UInt8((value >> $0) & 0x7F) })
    }
}
