import Foundation

extension Data {
    mutating func write<T: FixedWidthInteger>(_ value: T, at offset: Int) {
        Swift.withUnsafeBytes(of: value.littleEndian) { bytes in
            replaceSubrange(offset..<offset + bytes.count, with: bytes)
        }
    }
}
