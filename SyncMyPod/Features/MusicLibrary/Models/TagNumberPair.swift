import Foundation

/// The iTunes `trkn`/`disk` atom payload: two reserved bytes, then big-endian number and count.
nonisolated struct TagNumberPair: Equatable, Sendable {
    var number = 0
    var count = 0

    init(number: Int = 0, count: Int = 0) {
        self.number = number
        self.count = count
    }

    init(atomData data: Data) {
        let bytes = Array(data)
        guard bytes.count >= 6 else { return }
        number = Int(bytes[2]) << 8 | Int(bytes[3])
        count = Int(bytes[4]) << 8 | Int(bytes[5])
    }

    /// An ID3 `TRCK`/`TPOS` value such as `"3"` or `"3/12"`.
    init(text: String) {
        let parts = text.split(separator: "/").map { Int($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
        number = parts.first ?? 0
        count = parts.count > 1 ? parts[1] : 0
    }
}
