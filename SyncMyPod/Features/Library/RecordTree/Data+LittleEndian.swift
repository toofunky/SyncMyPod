import Foundation

nonisolated extension Data {
    mutating func write<T: FixedWidthInteger>(_ value: T, at offset: Int) {
        Swift.withUnsafeBytes(of: value.littleEndian) { bytes in
            replaceSubrange(offset..<offset + bytes.count, with: bytes)
        }
    }

    /// Reads a little-endian integer at `offset` from the start of the data, or 0 if out of bounds.
    func read<T: FixedWidthInteger>(_ type: T.Type, at offset: Int) -> T {
        let size = MemoryLayout<T>.size
        guard offset >= 0, offset + size <= count else { return 0 }
        var value = T.zero
        Swift.withUnsafeMutableBytes(of: &value) { buffer in
            _ = copyBytes(to: buffer, from: startIndex + offset..<startIndex + offset + size)
        }
        return T(littleEndian: value)
    }
}
