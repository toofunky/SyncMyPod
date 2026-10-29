import Foundation

/// The obfuscated EDON-R based hash hashAB uses to expand its key material (dstaley/hashab's src/hash.c).
nonisolated enum HashABDigest {
    private static let inputMultiplier: UInt32 = 0xA272_BE3F
    private static let combineMultiplier: UInt32 = 0x7F86_31BF
    private static let byteMultiplier: UInt32 = 0xC83B_EBC7
    private static let wordBias: UInt32 = 0x44E5_7C7E
    private static let rotateInput: UInt32 = 0x1E05_1C21

    /// Hashes the 64-byte `work` buffer to 32 bytes; like the C code, it leaves the final block in `work`.
    static func digest(_ work: inout [UInt8]) -> [UInt8] {
        var block = (0..<16).map { preprocess(work.littleEndianWord(at: $0 * 4)) }
        var edonR = EdonR256()
        for round in 0..<4 {
            edonR.compress(block)
            if round != 3 { block = edonR.state.map(stateToWord) }
        }
        for (index, word) in block.enumerated() {
            work.setLittleEndianWord(word, at: index * 4)
        }
        var output = [UInt8](repeating: 0, count: 32)
        for index in 0..<8 {
            output.setLittleEndianWord(edonR.state[8 + index] &* 0xF46E_F4FF, at: index * 4)
        }
        return output
    }

    private static func preprocess(_ input: UInt32) -> UInt32 {
        let bytes = (0..<4).map { UInt32(byteTables[$0][Int((input >> ($0 * 8)) & 0xFF)]) }
        let first = ((bytes[0] &* 0xC9 &* 0x79) & 0xFF) << 8
        var partial = mix(bytes[1] &* 0xC9 & 0xFF) &+ first &* inputMultiplier
        partial = mix(bytes[2]) &+ partial &+ spread(partial)
        partial = mix(bytes[3]) &+ partial &+ spread(partial)
        partial = partial &+ spread(partial)
        return partial &* combineMultiplier
    }

    private static func stateToWord(_ canonical: UInt32) -> UInt32 {
        let stateWord = canonical &* 0xC2ED_397F &* 0xBCB9_5B41
        var rotated = rotate((stateWord &+ mix(lookup(0, stateWord) &* 0xC9 & 0xFF)) &* rotateInput, 11)
        rotated = rotated &* inputMultiplier
        let combined = mix(lookup(1, rotated) &* 0xC9 & 0xFF)
        let merged = ((combined &* 0x00F3_9C82 &- 1) | (rotated &* 0x00F3_9C82 &- 1)) &* inputMultiplier
        rotated = rotate((merged &+ rotated &+ combined &- 0x5D8D_41C1) &* rotateInput, 10)
        let last = mix(lookup(2, rotated &* inputMultiplier))
        rotated = rotate((rotated &* inputMultiplier &- last) &* rotateInput, 7)
        return rotated &* inputMultiplier &* combineMultiplier
    }

    private static func mix(_ byte: UInt32) -> UInt32 {
        let highMask = ~(byte &* 0x79) | 0xFF
        return byte &* byteMultiplier &+ wordBias &+ ~highMask &* inputMultiplier &+ highMask &* wordBias
    }

    private static func spread(_ value: UInt32) -> UInt32 {
        value &* combineMultiplier &* 0x100 &* inputMultiplier
    }

    private static func lookup(_ table: Int, _ value: UInt32) -> UInt32 {
        UInt32(byteTables[table][Int(UInt8(truncatingIfNeeded: value &* 0xBF))])
    }

    private static func rotate(_ value: UInt32, _ count: UInt32) -> UInt32 {
        (value &* 0x8FA4_91DF).rotatedLeft(count)
    }
}
