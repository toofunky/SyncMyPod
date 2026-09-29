import Foundation

/// Stretches stage-one ciphertext into the 190 bytes of key material `HashABReducer` folds down.
nonisolated enum HashABExpander {
    private static let outputSize = 190

    /// Seeds with 24 ciphertext bytes from offset 20, then the first 20.
    static func expand(_ ciphertext: [UInt8]) -> [UInt8] {
        var work = [UInt8](repeating: 0, count: 64)
        for index in 0..<24 { work[index] = ciphertext[20 + index] &* 0x6F }
        for index in 0..<20 { work[24 + index] = ciphertext[index] &* 0x6F }
        work.setLittleEndianWord(12, at: 48)
        var output: [UInt8] = []
        for iteration in 0..<6 {
            work.setLittleEndianWord(UInt32(iteration), at: 44)
            output += transform(HashABDigest.digest(&work))
        }
        return Array(output.prefix(outputSize))
    }

    private static func transform(_ digest: [UInt8]) -> [UInt8] {
        (0..<8).flatMap { index -> [UInt8] in
            let word = digest.littleEndianWord(at: index * 4)
            let product = word &* 0xC818_0AFF
            return [UInt8(truncatingIfNeeded: word &* 0x6B)]
                + (1..<4).map { UInt8(truncatingIfNeeded: (product >> ($0 * 8)) &* 0x95) }
        }
    }
}
