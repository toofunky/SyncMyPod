/*
 Swift port of dstaley/hashab (https://github.com/dstaley/hashab), a clean-room
 reimplementation of the hashAB signature, released into the public domain under
 The Unlicense. The database framing follows libgpod's src/itdb_hashAB.c.
*/
import CryptoKit
import Foundation

/// Signs an iTunesCDB for iPod nano 6G/7G firmware: a 57-byte signature over the file's SHA-1 and the FireWire ID.
nonisolated struct HashAB: IPodDatabaseSigner {
    /// libgpod's ITDB_CHECKSUM_HASHAB, and what iTunes writes on a nano 7G.
    static let scheme: UInt16 = 3
    static let schemeOffset = 0x30
    static let signatureRange = 0xAB..<0xE4
    /// libgpod's fixed filler; iTunes uses random bytes, which the signature carries in the clear.
    static let libgpodRandomBytes = Array("ABCDEFGHIJKLMNOPQRSTUVW".utf8)

    private static let zeroedRanges = [0x18..<0x20, 0x58..<0x6C, 0x72..<0xA0, signatureRange]
    private static let signatureVersion: [UInt8] = [3, 0]
    private static let randomCount = 23
    private static let stage2Permutation = [
        0x06, 0x18, 0x11, 0x07, 0x13, 0x0D, 0x0E, 0x09, 0x15, 0x1D, 0x02, 0x1F, 0x01, 0x04, 0x1C, 0x1A,
        0x10, 0x14, 0x0B, 0x1E, 0x03, 0x0A, 0x1B, 0x19, 0x05, 0x0F, 0x16, 0x00, 0x12, 0x17, 0x08, 0x0C
    ]
    private static let signaturePermutation = [
        0x15, 0x1C, 0x06, 0x0C, 0x07, 0x1A, 0x05, 0x13, 0x08, 0x19, 0x03, 0x01, 0x2D, 0x1E,
        0x10, 0x31, 0x1D, 0x14, 0x28, 0x27, 0x35, 0x00, 0x2F, 0x1B, 0x26, 0x0B, 0x0E, 0x02,
        0x23, 0x17, 0x24, 0x22, 0x12, 0x1F, 0x20, 0x04, 0x29, 0x25, 0x21, 0x09, 0x18, 0x0D,
        0x32, 0x0F, 0x11, 0x2E, 0x33, 0x2B, 0x30, 0x2A, 0x36, 0x0A, 0x2C, 0x34, 0x16
    ]

    let fireWireID: FireWireID

    /// Returns `database` with the hashing scheme set and the hashAB field filled in.
    func sign(_ database: Data) throws -> Data {
        try sign(database, randomBytes: Self.libgpodRandomBytes)
    }

    func sign(_ database: Data, randomBytes: [UInt8]) throws -> Data {
        guard database.prefix(4) == Data("mhbd".utf8),
              database.read(UInt32.self, at: 0x04) >= Self.signatureRange.upperBound,
              database.count >= Self.signatureRange.upperBound, randomBytes.count == Self.randomCount else {
            throw ITunesDBError.invalidLength(offset: 0)
        }
        var signed = database
        signed.write(Self.scheme, at: Self.schemeOffset)
        let signature = Self.signature(sha1: Self.digest(of: signed), uuid: fireWireID.bytes, random: randomBytes)
        signed.replaceSubrange(Self.signatureRange, with: signature)
        return signed
    }

    /// Whether the stored signature is the one this device produces, whichever random bytes it was made with.
    func isValid(_ database: Data) -> Bool {
        guard database.count >= Self.signatureRange.upperBound else { return false }
        let stored = [UInt8](database.subdata(in: Self.signatureRange))
        guard let random = Self.randomBytes(in: stored) else { return false }
        return stored == Self.signature(sha1: Self.digest(of: database), uuid: fireWireID.bytes, random: random)
    }

    static func isSigned(_ database: Data) -> Bool {
        database.count >= signatureRange.upperBound && database.read(UInt16.self, at: schemeOffset) == scheme
    }

    /// Signs a SHA-1 digest directly, as Locations.itdb.cbk does.
    func signature(forDigest sha1: [UInt8], randomBytes: [UInt8] = libgpodRandomBytes) -> [UInt8] {
        Self.signature(sha1: sha1, uuid: fireWireID.bytes, random: randomBytes)
    }

    static func signature(sha1: [UInt8], uuid: [UInt8], random: [UInt8]) -> [UInt8] {
        let input = (uuid.prefix(8) + sha1 + random).map { $0 &* 0xED }
        let stage1 = HashABCipher.stage1.encrypt(input + [UInt8](repeating: 0xC1, count: 80 - input.count),
                                                 chain: HashABCipher.stage1InitialChain)
        let iv = HashABReducer.reduce(HashABExpander.expand(stage1))
        let stage2 = HashABCipher.stage2.encrypt(stage2Permutation.map { stage1[44 + $0] },
                                                 chain: HashABCipher.stage2.chain(fromOutput: iv))
        return signatureVersion + signaturePermutation.map { source in
            source < randomCount ? random[source] : stage2[source - randomCount] &* 0x2D
        }
    }

    /// Recovers the random bytes a signature was made with; they're stored unencrypted among its bytes.
    static func randomBytes(in signature: [UInt8]) -> [UInt8]? {
        guard signature.count == signatureRange.count, signature.starts(with: signatureVersion) else { return nil }
        var random = [UInt8](repeating: 0, count: randomCount)
        for (index, source) in signaturePermutation.enumerated() where source < randomCount {
            random[source] = signature[index + signatureVersion.count]
        }
        return random
    }

    private static func digest(of database: Data) -> [UInt8] {
        var prepared = database
        for range in zeroedRanges { prepared.replaceSubrange(range, with: Data(count: range.count)) }
        return Array(Insecure.SHA1.hash(data: prepared))
    }
}
