import Foundation

/// Converts 8-bit RGBX pixels to the iPod's RGB565 little-endian layout.
nonisolated enum RGB565Packer {
    static func pack(rgbx: UnsafeRawBufferPointer, pixelCount: Int) -> Data {
        var output = Data(count: pixelCount * 2)
        output.withUnsafeMutableBytes { destination in
            for index in 0..<pixelCount {
                let source = index * 4
                let value = pack(red: rgbx[source], green: rgbx[source + 1], blue: rgbx[source + 2])
                destination[index * 2] = UInt8(truncatingIfNeeded: value)
                destination[index * 2 + 1] = UInt8(truncatingIfNeeded: value >> 8)
            }
        }
        return output
    }

    static func pack(red: UInt8, green: UInt8, blue: UInt8) -> UInt16 {
        scale(red, to: 31) << 11 | scale(green, to: 63) << 5 | scale(blue, to: 31)
    }

    private static func scale(_ component: UInt8, to maximum: UInt16) -> UInt16 {
        (UInt16(component) * maximum + 127) / 255
    }
}
