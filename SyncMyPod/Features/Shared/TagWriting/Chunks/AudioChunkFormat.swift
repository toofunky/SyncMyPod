import Foundation

/// The two chunked audio containers: RIFF (WAV), whose sizes are little-endian, and IFF (AIFF and
/// AIFF-C), whose sizes are big-endian. Both start with a 12-byte header whose size covers the rest.
nonisolated enum AudioChunkFormat: Sendable {
    case riff
    case aiff

    static let headerLength = 12

    init?(header: Data) {
        guard header.count >= Self.headerLength else { return nil }
        let id = String(decoding: header.prefix(4), as: UTF8.self)
        let form = String(decoding: header.dropFirst(8).prefix(4), as: UTF8.self)
        switch (id, form) {
        case ("RIFF", "WAVE"): self = .riff
        case ("FORM", "AIFF"), ("FORM", "AIFC"): self = .aiff
        default: return nil
        }
    }

    /// WAV taggers write `id3 ` and AIFF taggers `ID3 `, but either may turn up in either.
    var id3ChunkID: String { self == .riff ? "id3 " : "ID3 " }

    func isID3Chunk(_ id: String) -> Bool { id.uppercased() == "ID3 " }

    func size(in data: Data, at offset: Int) -> Int {
        switch self {
        case .riff: Int(data.read(UInt32.self, at: offset))
        case .aiff: Int(data.readBigEndian(UInt32.self, at: offset))
        }
    }

    func encoded(size: Int) -> Data {
        var data = Data(count: 4)
        switch self {
        case .riff: data.write(UInt32(size), at: 0)
        case .aiff: data.writeBigEndian(UInt32(size), at: 0)
        }
        return data
    }

    /// The chunk's header and body, plus the pad byte that keeps the next chunk at an even offset.
    func chunk(id: String, body: Data) -> Data {
        var data = Data(id.utf8) + encoded(size: body.count) + body
        if body.count.isMultiple(of: 2) == false { data.append(0) }
        return data
    }
}
