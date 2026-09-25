import AVFoundation
import Testing
@testable import SyncMyPod

struct AACMetadataReaderTests {
    @Test func readsAACFile() async throws {
        let folder = try AudioFixtureWriter.makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.m4a"), seconds: 2)

        let metadata = try #require(try await AACMetadataReader().read(url))
        #expect(abs(metadata.duration - 2) < 0.1)
        #expect(metadata.sampleRate == 44_100)
        #expect(metadata.tags == AudioTags())
    }

    @Test func rejectsALACFile() async throws {
        let folder = try AudioFixtureWriter.makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "lossless.m4a"),
                                                      format: kAudioFormatAppleLossless)
        #expect(try await AACMetadataReader().read(url) == nil)
    }
}
