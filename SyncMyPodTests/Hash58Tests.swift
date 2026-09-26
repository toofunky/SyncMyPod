import Foundation
import Testing
@testable import SyncMyPod

/// Expected values come from compiling libgpod's itdb_hash58.c unmodified against the same inputs.
struct Hash58Tests {
    private let database = ITunesDBFixtureBuilder(
        tracks: [FixtureTrack(id: 7, title: "Clocks", artist: "Coldplay", album: "A Rush",
                              location: ":iPod_Control:Music:F00:ABCD.m4a")],
        playlists: [FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [7])]
    ).build()

    private func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    private func signer(_ id: String) throws -> Hash58 {
        Hash58(fireWireID: try #require(FireWireID(hexString: id)))
    }

    @Test(arguments: [("000A270015D4335D", "9cd045572bb4a379664cf6325dd87e16b4ddb0f2"),
                      ("0123456789ABCDEF", "66d29d91961cc67a801e685ded026ced2b1332d4"),
                      ("00000000000000FF", "5b37a41c70c3712fcc40551603ec42c770456929")])
    func matchesLibgpod(fireWireID: String, expectedHash: String) throws {
        let signed = try signer(fireWireID).sign(database)
        #expect(hex(signed.subdata(in: Hash58.hashRange)) == expectedHash)
    }

    @Test func onlyTouchesTheSchemeAndHashFields() throws {
        let signed = try signer("000A270015D4335D").sign(database)
        #expect(signed.read(UInt16.self, at: Hash58.schemeOffset) == Hash58.scheme)
        var unsignedAgain = signed
        unsignedAgain.write(UInt16(0), at: Hash58.schemeOffset)
        unsignedAgain.replaceSubrange(Hash58.hashRange, with: Data(count: Hash58.hashRange.count))
        #expect(unsignedAgain == database)
    }

    @Test func validatesOnlyWithTheMatchingDevice() throws {
        let signed = try signer("000A270015D4335D").sign(database)
        #expect(try signer("000A270015D4335D").isValid(signed))
        #expect(try !signer("0123456789ABCDEF").isValid(signed))
        #expect(try !signer("000A270015D4335D").isValid(database))
        var tampered = signed
        tampered[0x200] ^= 0xFF
        #expect(try !signer("000A270015D4335D").isValid(tampered))
    }

    @Test func aesTablesMatchKnownValues() {
        #expect(AESSubstitutionBox.forward[0x00] == 0x63 && AESSubstitutionBox.forward[0x53] == 0xED)
        #expect(AESSubstitutionBox.forward[0xFF] == 0x16)
        #expect((0...255).allSatisfy { AESSubstitutionBox.inverse[Int(AESSubstitutionBox.forward[$0])] == $0 })
    }

    @Test(arguments: ["000A270015D4335D", "0x000A270015D4335D", "000a270015d4335d"])
    func parsesFireWireIDs(text: String) {
        #expect(FireWireID(hexString: text)?.bytes == [0x00, 0x0A, 0x27, 0x00, 0x15, 0xD4, 0x33, 0x5D])
    }

    @Test(arguments: ["", "000A27", "000A270015D433ZZ"])
    func rejectsMalformedFireWireIDs(text: String) {
        #expect(FireWireID(hexString: text) == nil)
    }

    @Test(.enabled(if: RealDeviceFixture.data != nil, "No real iTunesDB fixture present"))
    func matchesLibgpodOnTheRealDatabase() throws {
        let signed = try signer("000A270015D4335D").sign(try #require(RealDeviceFixture.data))
        #expect(hex(signed.subdata(in: Hash58.hashRange)) == "81b1757f23b3a59aacb568796ba880588426cd8b")
    }
}
