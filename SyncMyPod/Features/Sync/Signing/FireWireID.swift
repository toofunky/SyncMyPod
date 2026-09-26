import Foundation

/// The 8-byte device ID hash58 is keyed on, parsed from SysInfo's `FirewireGuid` hex string.
nonisolated struct FireWireID: Equatable, Sendable {
    private static let byteCount = 8

    let bytes: [UInt8]

    init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespaces)
        if hex.lowercased().hasPrefix("0x") { hex.removeFirst(2) }
        guard hex.count >= Self.byteCount * 2 else { return nil }
        let characters = Array(hex.prefix(Self.byteCount * 2))
        let parsed = stride(from: 0, to: characters.count, by: 2).compactMap {
            UInt8(String(characters[$0...$0 + 1]), radix: 16)
        }
        guard parsed.count == Self.byteCount else { return nil }
        bytes = parsed
    }
}
