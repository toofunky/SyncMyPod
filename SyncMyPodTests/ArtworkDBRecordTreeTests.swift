import Foundation
import Testing
@testable import SyncMyPod

@Suite(.enabled(if: RealDeviceFixture.artworkDB != nil, "No real ArtworkDB fixture present"))
struct ArtworkDBRecordTreeTests {
    private func parse() throws -> ITunesDBRecord {
        try ITunesDBRecordParser(data: #require(RealDeviceFixture.artworkDB), layout: .artworkDB).parse()
    }

    @Test func roundTripsRealArtworkDBByteForByte() throws {
        #expect(try parse().serialized() == RealDeviceFixture.artworkDB)
    }

    @Test func parsesNestedThumbnailRecords() throws {
        let root = try parse()
        #expect(root.tag == "mhfd")
        #expect(root.children.map(\.tag) == ["mhsd", "mhsd", "mhsd"])
        let image = try #require(root.children.first?.children.first?.children.first)
        #expect(image.tag == "mhii")
        let thumbnails = image.children.filter { $0.recordType & 0xFFFF == 2 }
        #expect(thumbnails.map { $0.children.first?.tag } == ["mhni", "mhni"])
        let formats = thumbnails.compactMap { $0.children.first?.uint32(at: 0x10) }
        #expect(formats == [1028, 1029])
    }

    @Test func listsBothCoverFormats() throws {
        let fileList = try #require(parse().children.last?.children.first)
        #expect(fileList.tag == "mhlf")
        #expect(fileList.children.map { $0.uint32(at: 0x10) } == [1028, 1029])
        #expect(fileList.children.map { $0.uint32(at: 0x14) } == [20_000, 80_000])
    }

    @Test func rejectsAnITunesDBParsedAsArtwork() throws {
        let iTunesDB = ITunesDBFixtureBuilder().build()
        #expect(throws: ITunesDBError.self) {
            try ITunesDBRecordParser(data: iTunesDB, layout: .artworkDB).parse()
        }
    }
}
