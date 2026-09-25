import AVFoundation
import Testing
@testable import SyncMyPod

struct AudioMetadataReaderTests {
    @Test func readsAACFile() async throws {
        let folder = try AudioFixtureWriter.makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.m4a"), seconds: 2)

        let metadata = try #require(try await AudioMetadataReader().read(url))
        #expect(metadata.codec == .aac)
        #expect(abs(metadata.duration - 2) < 0.1)
        #expect(metadata.sampleRate == 44_100)
        #expect(metadata.tags == AudioTags())
    }

    @Test func readsALACFile() async throws {
        let folder = try AudioFixtureWriter.makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "lossless.m4a"),
                                                      format: kAudioFormatAppleLossless, seconds: 2)

        let metadata = try #require(try await AudioMetadataReader().read(url))
        #expect(metadata.codec == .alac)
        #expect(abs(metadata.duration - 2) < 0.1)
        #expect(metadata.sampleRate == 44_100)
    }

    @Test func readsMP3FileWithID3Tags() async throws {
        let folder = try AudioFixtureWriter.makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let tags = ["TIT2": "Float On", "TPE1": "Modest Mouse", "TALB": "Good News", "TPE2": "Various",
                    "TCON": "Indie", "TYER": "2004", "TRCK": "3/16", "TPOS": "1/2"]
        let url = try MP3FixtureWriter.write(to: folder.appending(path: "song.mp3"), seconds: 2, tags: tags)

        let metadata = try #require(try await AudioMetadataReader().read(url))
        #expect(metadata.codec == .mp3)
        #expect(abs(metadata.duration - 2) < 0.1)
        #expect(metadata.sampleRate == 44_100 && (120...130).contains(metadata.bitrate))
        #expect(metadata.tags == AudioTags(title: "Float On", artist: "Modest Mouse", album: "Good News",
                                           albumArtist: "Various", genre: "Indie", year: 2004,
                                           track: TagNumberPair(number: 3, count: 16),
                                           disc: TagNumberPair(number: 1, count: 2)))
    }

    @Test func rejectsFileWithoutAudio() async throws {
        let folder = try AudioFixtureWriter.makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "broken.mp3")
        try Data("not audio".utf8).write(to: url)
        #expect(await (try? AudioMetadataReader().read(url)) == nil)
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
            fingerprints.append(try #require(try await AudioMetadataReader().read(url)).artworkFingerprint)
        }
        #expect(try #require(try await AudioMetadataReader().read(plain)).artworkFingerprint == nil)
        #expect(fingerprints[0] != nil && fingerprints[0] == fingerprints[1])
        #expect(fingerprints[0] != fingerprints[2])
    }
}
