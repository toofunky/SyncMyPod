import Foundation

/// A four-byte MP4 box or ID3 frame identifier, spelled in ISO Latin-1 so `©` is the single byte 0xA9.
nonisolated struct FourCC: Hashable, Sendable, CustomStringConvertible {
    let rawValue: UInt32

    init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    init(_ string: String) {
        let bytes = string.data(using: .isoLatin1) ?? Data()
        precondition(bytes.count == 4, "A FourCC needs exactly four Latin-1 characters")
        rawValue = bytes.readBigEndian(UInt32.self, at: 0)
    }

    var description: String {
        var data = Data()
        data.appendBigEndian(rawValue)
        return String(data: data, encoding: .isoLatin1) ?? "????"
    }
}
