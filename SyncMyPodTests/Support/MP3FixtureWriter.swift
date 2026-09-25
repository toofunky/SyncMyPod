import Foundation

/// Writes silent 128 kbps / 44.1 kHz MPEG-1 Layer III frames behind an optional ID3v2.3 tag.
nonisolated enum MP3FixtureWriter {
    private static let frameHeader: [UInt8] = [0xFF, 0xFB, 0x90, 0x00]
    private static let frameLength = 417
    private static let samplesPerFrame = 1_152.0

    @discardableResult
    static func write(to url: URL, seconds: Double = 1, tags: [String: String] = [:]) throws -> URL {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let frame = frameHeader + [UInt8](repeating: 0, count: frameLength - frameHeader.count)
        let frameCount = Int((seconds * AudioFixtureWriter.sampleRate / samplesPerFrame).rounded())
        var data = id3Tag(tags)
        for _ in 0..<frameCount { data.append(contentsOf: frame) }
        try data.write(to: url)
        return url
    }

    /// `tags` maps ID3 frame IDs (e.g. `TIT2`) to Latin-1 text.
    private static func id3Tag(_ tags: [String: String]) -> Data {
        guard !tags.isEmpty else { return Data() }
        var body = Data()
        for (id, value) in tags.sorted(by: { $0.key < $1.key }) {
            let text = [UInt8(0)] + Array(value.utf8)
            body.append(contentsOf: Array(id.utf8) + bigEndian(text.count) + [0, 0] + text)
        }
        return Data("ID3".utf8) + [3, 0, 0] + synchsafe(body.count) + body
    }

    private static func bigEndian(_ value: Int) -> [UInt8] {
        [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: value >> $0) }
    }

    private static func synchsafe(_ value: Int) -> [UInt8] {
        [21, 14, 7, 0].map { UInt8((value >> $0) & 0x7F) }
    }
}
