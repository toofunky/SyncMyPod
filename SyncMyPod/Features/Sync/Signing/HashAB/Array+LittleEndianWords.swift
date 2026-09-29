import Foundation

nonisolated extension Array where Element == UInt8 {
    func littleEndianWord(at offset: Int) -> UInt32 {
        (0..<4).reduce(UInt32(0)) { word, byte in word | UInt32(self[offset + byte]) << (byte * 8) }
    }

    mutating func setLittleEndianWord(_ value: UInt32, at offset: Int) {
        for byte in 0..<4 {
            self[offset + byte] = UInt8(truncatingIfNeeded: value >> (byte * 8))
        }
    }
}
