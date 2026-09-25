import AVFoundation
import Foundation
import Testing

nonisolated enum AudioFixtureWriter {
    static let sampleRate = 44_100.0

    static func makeTemporaryFolder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString,
                                                                   directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @discardableResult
    static func writeSilence(to url: URL, format: AudioFormatID = kAudioFormatMPEG4AAC,
                             seconds: Double = 1) throws -> URL {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let settings: [String: Any] = [AVFormatIDKey: format, AVSampleRateKey: sampleRate,
                                       AVNumberOfChannelsKey: 2, AVEncoderBitDepthHintKey: 16]
        let file = try AVAudioFile(forWriting: url, settings: settings)
        let frames = AVAudioFrameCount(sampleRate * seconds)
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frames))
        buffer.frameLength = frames
        try file.write(from: buffer)
        return url
    }
}
