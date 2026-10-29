import Foundation

nonisolated extension Data {
    /// Reads a big-endian integer at `offset` from the start of the data, or 0 if out of bounds.
    func readBigEndian<T: FixedWidthInteger>(_ type: T.Type, at offset: Int) -> T {
        let size = MemoryLayout<T>.size
        guard offset >= 0, offset + size <= count else { return 0 }
        return self[startIndex + offset..<startIndex + offset + size].reduce(T.zero) { $0 << 8 | T($1) }
    }

    mutating func writeBigEndian<T: FixedWidthInteger>(_ value: T, at offset: Int) {
        Swift.withUnsafeBytes(of: value.bigEndian) { bytes in
            replaceSubrange(startIndex + offset..<startIndex + offset + bytes.count, with: bytes)
        }
    }

    mutating func appendBigEndian<T: FixedWidthInteger>(_ value: T) {
        Swift.withUnsafeBytes(of: value.bigEndian) { append(contentsOf: $0) }
    }
}
