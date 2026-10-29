import Foundation

/// One block of a FLAC file's metadata: a type and its body, whose 24-bit length the header gives.
nonisolated struct FLACMetadataBlock: Equatable, Sendable {
    static let streamInfo: UInt8 = 0
    static let padding: UInt8 = 1
    static let vorbisComment: UInt8 = 4
    static let picture: UInt8 = 6
    static let maximumLength = (1 << 24) - 1
    static let headerLength = 4

    let type: UInt8
    let body: Data

    func serialized(isLast: Bool) -> Data {
        var data = Data([type | (isLast ? 0x80 : 0)])
        data.append(contentsOf: [UInt8(body.count >> 16 & 0xFF), UInt8(body.count >> 8 & 0xFF),
                                 UInt8(body.count & 0xFF)])
        return data + body
    }
}
