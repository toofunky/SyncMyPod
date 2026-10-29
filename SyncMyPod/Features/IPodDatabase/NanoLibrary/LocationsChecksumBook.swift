import CryptoKit
import Foundation

/// Locations.itdb.cbk: a hashAB signature over the SHA-1 of every 1 KB block's SHA-1, then those digests.
nonisolated enum LocationsChecksumBook {
    static let fileName = "Locations.itdb.cbk"
    private static let blockSize = 1024
    private static let signatureLength = HashAB.signatureRange.count

    static func make(for locations: Data, signer: HashAB) -> Data {
        let blockDigests = digests(of: locations)
        let digest = Array(Insecure.SHA1.hash(data: blockDigests))
        return Data(signer.signature(forDigest: digest)) + Data(digest) + blockDigests
    }

    /// Whether `book` matches `locations` and carries this device's signature, whatever random bytes it used.
    static func isValid(_ book: Data, for locations: Data, signer: HashAB) -> Bool {
        let blockDigests = digests(of: locations)
        let digest = Array(Insecure.SHA1.hash(data: blockDigests))
        let signature = [UInt8](book.prefix(signatureLength))
        guard let random = HashAB.randomBytes(in: signature),
              book.dropFirst(signatureLength) == Data(digest) + blockDigests else { return false }
        return signature == signer.signature(forDigest: digest, randomBytes: random)
    }

    private static func digests(of data: Data) -> Data {
        stride(from: 0, to: data.count, by: blockSize).reduce(into: Data()) { result, offset in
            let block = data[data.startIndex + offset..<data.startIndex + min(offset + blockSize, data.count)]
            result.append(contentsOf: Insecure.SHA1.hash(data: block))
        }
    }
}
