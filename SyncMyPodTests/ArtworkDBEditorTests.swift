import Foundation
import Testing
@testable import SyncMyPod

struct ArtworkDBEditorTests {
    private let formats = ArtworkFormat.videoIPod
    private var thumbnails: [ArtworkThumbnail] {
        [ArtworkThumbnail(format: formats[0], offset: 20_000, horizontalPadding: 0, verticalPadding: 12),
         ArtworkThumbnail(format: formats[1], offset: 80_000, horizontalPadding: 0, verticalPadding: 25)]
    }

    private func images(in data: Data) throws -> [ITunesDBRecord] {
        let root = try ITunesDBRecordParser(data: data, layout: .artworkDB).parse()
        return try #require(root.children.first?.children.first).children
    }

    private func thumbnailRecords(of image: ITunesDBRecord) -> [ITunesDBRecord] {
        image.children.compactMap { $0.children.first { $0.tag == "mhni" } }
    }

    @Test func emptyDatabaseListsTheFormatsAndRoundTrips() throws {
        let data = ArtworkDBEditor.empty(formats: formats).serialized()
        let root = try ITunesDBRecordParser(data: data, layout: .artworkDB).parse()
        #expect(root.children.count == 3)
        #expect(root.uint32(at: 0x1C) == 100)
        let files = try #require(root.children.last?.children.first)
        #expect(files.children.map { $0.uint32(at: 0x10) } == [1028, 1029])
        #expect(root.serialized() == data)
    }

    @Test func addedImageRecordsTrackAndThumbnails() throws {
        var editor = ArtworkDBEditor.empty(formats: formats)
        let id = editor.allocateImageID()
        editor.addImage(id: id, trackDatabaseID: 0xABCD, thumbnails: thumbnails)
        let image = try #require(try images(in: editor.serialized()).first)
        #expect(image.uint32(at: 0x10) == 100)
        #expect(image.uint64(at: 0x14) == 0xABCD)
        let mhnis = thumbnailRecords(of: image)
        #expect(mhnis.map { $0.uint32(at: 0x10) } == [1028, 1029])
        #expect(mhnis.map { $0.uint32(at: 0x14) } == [20_000, 80_000])
        #expect(mhnis.map { $0.uint32(at: 0x18) } == [20_000, 80_000])
        #expect(mhnis.map { $0.header.read(UInt16.self, at: 0x1C) } == [12, 25])
        #expect(mhnis.map { $0.header.read(UInt16.self, at: 0x22) } == [100, 200])
    }

    @Test func thumbnailNamesItsIthmbFile() throws {
        var editor = ArtworkDBEditor.empty(formats: formats)
        editor.addImage(id: editor.allocateImageID(), trackDatabaseID: 1, thumbnails: thumbnails)
        let image = try #require(try images(in: editor.serialized()).first)
        let mhni = try #require(thumbnailRecords(of: image).first)
        let fileName = try #require(mhni.children.first)
        guard case .container(_, let payload) = fileName.body else {
            Issue.record("Expected a filename mhod")
            return
        }
        let length = Int(payload.read(UInt32.self, at: 0x00))
        #expect(String(data: payload.subdata(in: 0x0C..<0x0C + length), encoding: .utf16LittleEndian) == ":F1028_1.ithmb")
    }

    @Suite(.enabled(if: RealDeviceFixture.artworkDB != nil, "No real ArtworkDB fixture present"))
    struct RealDevice {
        private let original = RealDeviceFixture.artworkDB ?? Data()

        @Test func unchangedEditorRoundTrips() throws {
            let root = try ITunesDBRecordParser(data: original, layout: .artworkDB).parse()
            #expect(ArtworkDBEditor(root: root).serialized() == original)
        }

        @Test func appendsAfterExistingImages() throws {
            let root = try ITunesDBRecordParser(data: original, layout: .artworkDB).parse()
            var editor = ArtworkDBEditor(root: root)
            let id = editor.allocateImageID()
            editor.addImage(id: id, trackDatabaseID: 7, thumbnails: [])
            let updated = try ITunesDBRecordParser(data: editor.serialized(), layout: .artworkDB).parse()
            let images = try #require(updated.children.first?.children.first).children
            #expect(id == 101)
            #expect(images.count == 2)
            #expect(images[0] == root.children.first?.children.first?.children.first)
            #expect(updated.uint32(at: 0x1C) == 102)
            #expect(updated.children.last?.children.first?.children.count == 2)
        }
    }
}
