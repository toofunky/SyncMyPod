import Foundation

nonisolated struct ID3Frame: Equatable, Sendable {
    static let headerSize = 10

    let id: FourCC
    var flags: UInt16 = 0
    var body: Data

    /// v2.4 stores frame sizes synchsafe; v2.3 stores them as plain big-endian integers.
    func serialized(majorVersion: UInt8) -> Data {
        var data = Data(capacity: Self.headerSize + body.count)
        data.appendBigEndian(id.rawValue)
        if majorVersion >= 4 {
            data.append(Synchsafe.encode(body.count))
        } else {
            data.appendBigEndian(UInt32(body.count))
        }
        data.appendBigEndian(flags)
        data.append(body)
        return data
    }
}
