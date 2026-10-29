import Foundation

/// An ID3v2.3 or v2.4 tag at the start of an MP3, and how many bytes it occupies there.
nonisolated struct ID3Tag: Equatable, Sendable {
    static let headerSize = 10
    static let defaultMajorVersion: UInt8 = 3

    var majorVersion = defaultMajorVersion
    var frames: [ID3Frame] = []
    /// Header, frames, padding and any footer of the tag already in the file; 0 when there is none.
    var existingLength = 0

    /// The whole tag, zero-padded to at least `minimumLength` bytes.
    func serialized(minimumLength: Int) -> Data {
        let frameData = frames.reduce(into: Data()) { $0.append($1.serialized(majorVersion: majorVersion)) }
        let bodyLength = max(frameData.count, minimumLength - Self.headerSize)
        var data = Data("ID3".utf8) + [majorVersion, 0, 0] + Synchsafe.encode(bodyLength)
        data.append(frameData)
        data.append(Data(count: bodyLength - frameData.count))
        return data
    }
}
