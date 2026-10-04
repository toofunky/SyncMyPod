import AVFoundation
import Foundation
import Testing
@testable import SyncMyPod

struct EmbeddedLyricsReaderTests {
    private static let lyrics = "Lights go out\nAnd I can't be saved"

    @Test(arguments: [SyncMyPod.AudioCodec.aac, .mp3, .flac])
    func readsBackWrittenLyricsAndNotesThem(codec: SyncMyPod.AudioCodec) async throws {
        let folder = try AudioFixtureWriter.makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try Self.song(codec, in: folder)
        #expect(try await EmbeddedLyricsReader().read(url) == "")

        try await TagWriter().write(TagChanges(lyrics: Self.lyrics), to: url, codec: codec)
        #expect(try await EmbeddedLyricsReader().read(url) == Self.lyrics)
        #expect(try #require(try await AudioMetadataReader().read(url)).tags.hasLyrics)

        try await TagWriter().write(TagChanges(lyrics: ""), to: url, codec: codec)
        #expect(try await EmbeddedLyricsReader().read(url) == "")
        #expect(try #require(try await AudioMetadataReader().read(url)).tags.hasLyrics == false)
    }

    private static func song(_ codec: SyncMyPod.AudioCodec, in folder: URL) throws -> URL {
        switch codec {
        case .mp3: try MP3FixtureWriter.write(to: folder.appending(path: "song.mp3"), tags: ["TIT2": "Clocks"])
        case .flac: try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.flac"),
                                                        format: kAudioFormatFLAC, seconds: 1)
        default: try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.m4a"))
        }
    }
}
