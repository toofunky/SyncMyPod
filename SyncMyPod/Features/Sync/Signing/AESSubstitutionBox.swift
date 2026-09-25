import Foundation

/// The AES S-box and its inverse, which hash58 uses as its two lookup tables.
nonisolated enum AESSubstitutionBox {
    private static let affineConstant: UInt8 = 0x63
    private static let reductionPolynomial: UInt8 = 0x1B

    static let forward: [UInt8] = (0...255).map { substitute(UInt8($0)) }

    static let inverse: [UInt8] = {
        var table = [UInt8](repeating: 0, count: 256)
        for (input, output) in forward.enumerated() { table[Int(output)] = UInt8(input) }
        return table
    }()

    private static func substitute(_ value: UInt8) -> UInt8 {
        let b = multiplicativeInverse(value)
        return b ^ rotateLeft(b, 1) ^ rotateLeft(b, 2) ^ rotateLeft(b, 3) ^ rotateLeft(b, 4) ^ affineConstant
    }

    /// `value^254` in GF(2^8), which is its inverse; 0 maps to 0.
    private static func multiplicativeInverse(_ value: UInt8) -> UInt8 {
        guard value != 0 else { return 0 }
        var result: UInt8 = 1
        var base = value
        var exponent = 254
        while exponent > 0 {
            if exponent & 1 == 1 { result = multiply(result, base) }
            base = multiply(base, base)
            exponent >>= 1
        }
        return result
    }

    private static func multiply(_ lhs: UInt8, _ rhs: UInt8) -> UInt8 {
        var a = lhs, b = rhs, product: UInt8 = 0
        for _ in 0..<8 {
            if b & 1 != 0 { product ^= a }
            let carries = a & 0x80 != 0
            a <<= 1
            if carries { a ^= reductionPolynomial }
            b >>= 1
        }
        return product
    }

    private static func rotateLeft(_ value: UInt8, _ count: UInt8) -> UInt8 {
        value << count | value >> (8 - count)
    }
}
