import Foundation
import Testing
@testable import SyncMyPod

/// Expected signatures come from dstaley/hashab's test-data.json, generated with the original libhashab32.so.
struct HashABTests {
    private let database = ITunesDBFixtureBuilder(
        tracks: [FixtureTrack(id: 7, title: "Clocks", artist: "Coldplay", album: "A Rush",
                              location: ":iPod_Control:Music:F00:ABCD.m4a")],
        playlists: [FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [7])],
        databaseHeaderLength: 0xF4
    ).build()

    private func bytes(_ hex: String) -> [UInt8] {
        let characters = Array(hex)
        return stride(from: 0, to: characters.count, by: 2).compactMap {
            UInt8(String(characters[$0...$0 + 1]), radix: 16)
        }
    }

    private func signer(_ id: String) throws -> HashAB {
        HashAB(fireWireID: try #require(FireWireID(hexString: id)))
    }

    @Test(arguments: [
        ("915dd7203086aeea302740e97febb7aefa9ca9f1", "f832c65917da6785",
         "030056d7474d4843465449bd444266eb516bf4552726b94169d1424c4f433a8208fc5345e34507c3fe4a8f4e8a5052664515aad30e4b195c57"),
        ("bc92e8760c26b3e5b46810476756ae5e4ad8252e", "c65b1d6417fab8fb",
         "0300560a474d4884465449e9444227a851338455640e4541016e2f4c4f4357542b0853995145f8c0364ae44e17505237bb4105171e4b41d857"),
        ("55422cc6d7fbdbe25da1271146bb56963dc46d9b", "d524bad6d23a87e1",
         "030056ff474d48b04654493044425334514999556deca841f8a7ef4c4f43803cf136530717459784934aa04eea50524b9bc13987e04b9bde57"),
        ("9c62f06e84d27856e432e9f60d045f175cbb72cc", "41aac2d49c47be3a",
         "030056e3474d4895465449104442a21051721055b44a06414fd85d4c4f43867e5f9d5357bd455fb4234a9d4e4850520d2b09892c014b88b957"),
        ("2529688e002d6a85dfdf80f60fa8de36a53f150c", "79206d8b96ee0f3f",
         "0300560a474d48ab465449844442f18951b02655d4c470411a58034c4f431038e6b25350b24522746e4a344e4f5052153987ca9c994bb2ae57")
    ])
    func matchesLibhashab(sha1: String, uuid: String, expected: String) {
        let signature = HashAB.signature(sha1: bytes(sha1), uuid: bytes(uuid), random: HashAB.libgpodRandomBytes)
        #expect(signature == bytes(expected))
    }

    @Test func recoversTheRandomBytesFromASignature() {
        let random = (0..<23).map { UInt8($0 * 11) }
        let signature = HashAB.signature(sha1: Array(repeating: 1, count: 20), uuid: Array(repeating: 2, count: 8),
                                         random: random)
        #expect(HashAB.randomBytes(in: signature) == random)
    }

    @Test func onlyTouchesTheSchemeAndSignatureFields() throws {
        let signed = try signer("000A270015D4335D").sign(database)
        #expect(signed.read(UInt16.self, at: HashAB.schemeOffset) == HashAB.scheme)
        var unsignedAgain = signed
        unsignedAgain.write(UInt16(0), at: HashAB.schemeOffset)
        unsignedAgain.replaceSubrange(HashAB.signatureRange, with: Data(count: HashAB.signatureRange.count))
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

    @Test func refusesHeadersTooShortForTheSignature() throws {
        let classicLayout = ITunesDBFixtureBuilder(playlists: [FixturePlaylist(id: 1, name: "iPod", isMaster: true,
                                                                              trackIDs: [])]).build()
        #expect(throws: ITunesDBError.invalidLength(offset: 0)) { _ = try signer("000A270015D4335D").sign(classicLayout) }
    }

    @Test func validatesSignaturesMadeWithOtherRandomBytes() throws {
        let random = Array("0123456789abcdefghijklm".utf8)
        let signed = try signer("000A270015D4335D").sign(database, randomBytes: random)
        #expect(try signer("000A270015D4335D").isValid(signed))
    }

    @Test(.enabled(if: RealDeviceFixture.compressedDatabase != nil
                   && RealDeviceFixture.compressedDatabaseFireWireID != nil,
                   "No real iTunesCDB fixture present"))
    func validatesTheSignatureITunesWrote() throws {
        let database = try #require(RealDeviceFixture.compressedDatabase)
        let signer = try signer(try #require(RealDeviceFixture.compressedDatabaseFireWireID))
        print("iTunesCDB hashing scheme at 0x30: \(database.read(UInt16.self, at: HashAB.schemeOffset))")
        #expect(signer.isValid(database))
    }
}
