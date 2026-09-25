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

    @Test func fingerprintsTheEmbeddedCover() async throws {
        let folder = try AudioFixtureWriter.makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let plain = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "plain.m4a"))
        let covers = [TestImage.color(1, 0, 0), TestImage.color(1, 0, 0), TestImage.color(0, 0, 1)]
        var fingerprints: [String?] = []
        for (index, color) in covers.enumerated() {
            let url = folder.appending(path: "\(index).m4a")
            let png = TestImage.pngData(TestImage.make(width: 64, height: 64, top: color))
            try await AudioFixtureWriter.embedCoverArt(png, from: plain, to: url)
            fingerprints.append(try #require(try await AACMetadataReader().read(url)).artworkFingerprint)
        }
        #expect(try #require(try await AACMetadataReader().read(plain)).artworkFingerprint == nil)
        #expect(fingerprints[0] != nil && fingerprints[0] == fingerprints[1])
        #expect(fingerprints[0] != fingerprints[2])
    }
}
