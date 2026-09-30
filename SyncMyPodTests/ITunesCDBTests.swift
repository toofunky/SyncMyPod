import Foundation
import Testing
@testable import SyncMyPod

struct ITunesCDBTests {
    private let database = ITunesDBFixtureBuilder(
        tracks: [FixtureTrack(id: 7, title: "Clocks", artist: "Coldplay", album: "A Rush",
                              location: ":iPod_Control:Music:F00:ABCD.m4a")],
        playlists: [FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [7])],
        databaseHeaderLength: 0xF4
    ).build()

    /// Frames the payload the way libgpod's compress2() does: zlib header, DEFLATE data, Adler-32 trailer.
    private func compress(_ database: Data) throws -> Data {
        let headerLength = Int(database.read(UInt32.self, at: 0x04))
        let payload = Data(database.dropFirst(headerLength))
        let deflated = try (payload as NSData).compressed(using: .zlib) as Data
        var compressed = Data(database.prefix(headerLength)) + Data([0x78, 0x01]) + deflated + Data(count: 4)
        compressed.write(UInt32(compressed.count), at: 0x08)
        compressed.write(UInt16(1), at: ITunesCDB.compressionFlagOffset)
        return compressed
    }

    @Test func decompressesBackToTheOriginalDatabase() throws {
        let compressed = try compress(database)
        #expect(ITunesCDB.isCompressed(compressed))
        #expect(try ITunesCDB.decompress(compressed) == database)
    }

    @Test func parsesTracksFromACompressedDatabase() throws {
        let parsed = try ITunesDBParser(data: ITunesCDB.decompress(try compress(database))).parse()
        #expect(parsed.tracks.map(\.title) == ["Clocks"])
    }

    @Test func leavesUncompressedDatabasesUnchanged() throws {
        #expect(!ITunesCDB.isCompressed(database))
        #expect(try ITunesCDB.decompress(database) == database)
    }

    @Test(.enabled(if: RealDeviceFixture.compressedDatabase != nil, "No real iTunesCDB fixture present"))
    func parsesTheRealCompressedDatabase() throws {
        let data = try #require(RealDeviceFixture.compressedDatabase)
        #expect(ITunesCDB.isCompressed(data))
        let parsed = try ITunesDBParser(data: ITunesCDB.decompress(data)).parse()
        print("iTunesCDB: \(parsed.tracks.count) tracks, \(parsed.playlists.count) playlists")
        #expect(!parsed.tracks.isEmpty)
    }
}
