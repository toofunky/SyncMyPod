import Foundation

/// A white-box AES-128 in CBC mode; hashAB runs two of these, each with its own baked-in tables.
nonisolated struct HashABCipher: Sendable {
    private static let blockSize = 16
    private static let rounds = 10

    let inputMap: [UInt8]
    let finalMap: [UInt8]
    let outputMap: [UInt8]
    let roundBase: [UInt8]
    let roundAffine: [[UInt8]]
    let schedule: [UInt8]

    /// `input.count` must be a multiple of 16.
    func encrypt(_ input: [UInt8], chain initialChain: [UInt8]) -> [UInt8] {
        var chaining = initialChain
        var output: [UInt8] = []
        output.reserveCapacity(input.count)
        for offset in stride(from: 0, to: input.count, by: Self.blockSize) {
            chaining = encryptBlock(Array(input[offset..<offset + Self.blockSize]), chaining: chaining)
            output += chaining.map { outputMap[Int($0)] }
        }
        return output
    }

    /// The internal chain value whose output-mapped form is `bytes`.
    func chain(fromOutput bytes: [UInt8]) -> [UInt8] {
        bytes.map { UInt8(outputMap.firstIndex(of: $0) ?? 0) }
    }

    private func encryptBlock(_ block: [UInt8], chaining: [UInt8]) -> [UInt8] {
        var state = (0..<Self.blockSize).map { inputMap[Int(block[$0])] ^ chaining[$0] ^ schedule[$0] }
        for round in 1..<Self.rounds {
            state = tableRound(state, roundKey: roundKey(round))
        }
        return finalRound(state, roundKey: roundKey(Self.rounds))
    }

    private func roundKey(_ round: Int) -> [UInt8] {
        Array(schedule[round * Self.blockSize..<(round + 1) * Self.blockSize])
    }

    private func tableRound(_ input: [UInt8], roundKey: [UInt8]) -> [UInt8] {
        var output = [UInt8](repeating: 0, count: Self.blockSize)
        for word in 0..<4 {
            var value = roundKey.littleEndianWord(at: word * 4)
            for table in 0..<4 {
                value ^= tableWord(table, index: input[(word * 4 + table * 5) & 15])
            }
            output.setLittleEndianWord(value, at: word * 4)
        }
        return output
    }

    private func finalRound(_ input: [UInt8], roundKey: [UInt8]) -> [UInt8] {
        (0..<Self.blockSize).map { position in
            let source = ((position & 12) + (position & 3) * 5) & 15
            return (finalMap[Int(input[source])] &* 0x81 &+ 0x7A) ^ roundKey[position]
        }
    }

    private func tableWord(_ table: Int, index: UInt8) -> UInt32 {
        let base = roundBase[Int(index)]
        return (0..<4).reduce(UInt32(0)) { word, byte in
            let lane = table * 4 + byte
            let value = lane == 0 ? base : affine(roundAffine[lane - 1], base)
            return word | UInt32(value) << (byte * 8)
        }
    }

    private func affine(_ parameters: [UInt8], _ value: UInt8) -> UInt8 {
        (0..<8).reduce(parameters[0]) { result, bit in
            (value >> bit) & 1 == 1 ? result ^ parameters[bit + 1] : result
        }
    }
}
