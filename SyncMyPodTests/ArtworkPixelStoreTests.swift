import Foundation
import Testing
@testable import SyncMyPod

struct ArtworkPixelStoreTests {
    private let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    private let format = ArtworkFormat.videoIPod[0]

    private func render(_ byte: UInt8) -> RenderedArtwork {
        RenderedArtwork(format: format, pixels: Data(repeating: byte, count: format.byteCount),
                        horizontalPadding: 0, verticalPadding: 0)
    }

    private var fileSize: Int {
        (try? Data(contentsOf: folder.appending(path: format.fileName)).count) ?? 0
    }

    @Test func appendsNewCoversAfterExistingData() throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        var store = ArtworkPixelStore(directoryURL: folder)
        #expect(try store.store([render(1)]).map(\.offset) == [0])
        #expect(try store.store([render(2)]).map(\.offset) == [20_000])
        #expect(fileSize == 40_000)
    }

    @Test func storesIdenticalCoversOnce() throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        var store = ArtworkPixelStore(directoryURL: folder)
        let first = try store.store([render(1)])
        #expect(try store.store([render(1)]) == first)
        #expect(fileSize == 20_000)
    }

    @Test func rollBackTruncatesToTheOriginalSize() throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(repeating: 9, count: 20_000).write(to: folder.appending(path: format.fileName))
        var store = ArtworkPixelStore(directoryURL: folder)
        #expect(try store.store([render(1)]).map(\.offset) == [20_000])
        store.rollBack()
        #expect(fileSize == 20_000)
    }
}
