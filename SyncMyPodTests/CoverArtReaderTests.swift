import CoreGraphics
import Foundation
import Testing
@testable import SyncMyPod

struct CoverArtReaderTests {
    @Test func readsEmbeddedCover() async throws {
        let folder = try AudioFixtureWriter.makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let silence = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "plain.m4a"))
        let cover = TestImage.make(width: 640, height: 480, top: TestImage.color(0, 1, 0))
        let tagged = folder.appending(path: "tagged.m4a")
        try await AudioFixtureWriter.embedCoverArt(TestImage.pngData(cover), from: silence, to: tagged)

        let pngData = TestImage.pngData(cover)
        let art = try #require(try await CoverArtReader().read(tagged))
        #expect(art.image.width == 640 && art.image.height == 480)
        #expect(art.byteCount == pngData.count)
    }

    @Test func returnsNilWithoutCover() async throws {
        let folder = try AudioFixtureWriter.makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let silence = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "plain.m4a"))
        #expect(try await CoverArtReader().read(silence) == nil)
    }
}
