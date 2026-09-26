import Foundation

nonisolated extension ITunesDBRecord {
    func uint8(at offset: Int) -> UInt8 { header.read(UInt8.self, at: offset) }
    func uint32(at offset: Int) -> UInt32 { header.read(UInt32.self, at: offset) }
    func uint64(at offset: Int) -> UInt64 { header.read(UInt64.self, at: offset) }

    mutating func set<T: FixedWidthInteger>(_ value: T, at offset: Int) {
        guard offset + MemoryLayout<T>.size <= header.count else { return }
        header.write(value, at: offset)
    }

    /// The `mhsd` section type or `mhod` record type.
    var recordType: UInt32 { uint32(at: 0x0C) }

    func isSection(_ type: ITunesDBSectionType) -> Bool {
        tag == "mhsd" && recordType == type.rawValue
    }

    var isMasterPlaylist: Bool { tag == "mhyp" && uint8(at: 0x14) == 1 }

    /// The string held by a child `mhod` of the given type, decoded as UTF-16 or UTF-8.
    func string(ofType type: UInt32) -> String? {
        guard let mhod = children.first(where: { $0.tag == "mhod" && $0.recordType == type }),
              case .opaque(let payload) = mhod.body else { return nil }
        let length = Int(payload.read(UInt32.self, at: 0x04))
        guard payload.count >= 0x10 + length else { return nil }
        let bytes = payload.subdata(in: 0x10..<0x10 + length)
        return payload.read(UInt32.self, at: 0x00) == 2
            ? String(decoding: bytes, as: UTF8.self)
            : String(data: bytes, encoding: .utf16LittleEndian)
    }
}
