import Foundation

/// Reads the thumbnails an `mhii` points at, limited to known formats stored in their standard `_1` file.
nonisolated enum ArtworkThumbnailParser {
    private static let thumbnailType: UInt16 = 2

    static func thumbnails(in image: ITunesDBRecord, formats: [ArtworkFormat]) -> [ArtworkThumbnail] {
        image.children
            .filter { $0.tag == "mhod" && UInt16(truncatingIfNeeded: $0.recordType) == thumbnailType }
            .compactMap { $0.children.first { $0.tag == "mhni" } }
            .compactMap { thumbnail(in: $0, formats: formats) }
    }

    static func fileName(of mhni: ITunesDBRecord) -> String? {
        guard let mhod = mhni.children.first(where: { $0.tag == "mhod" }),
              case .container(_, let payload) = mhod.body else { return nil }
        let length = Int(payload.read(UInt32.self, at: 0x00))
        guard payload.count >= 0x0C + length else { return nil }
        return String(data: payload.subdata(in: 0x0C..<0x0C + length), encoding: .utf16LittleEndian)
    }

    private static func thumbnail(in mhni: ITunesDBRecord, formats: [ArtworkFormat]) -> ArtworkThumbnail? {
        guard let format = formats.first(where: { $0.id == mhni.uint32(at: 0x10) }),
              fileName(of: mhni) == ":\(format.fileName)" else { return nil }
        return ArtworkThumbnail(format: format, offset: mhni.uint32(at: 0x14),
                                horizontalPadding: Int(mhni.header.read(Int16.self, at: 0x1E)),
                                verticalPadding: Int(mhni.header.read(Int16.self, at: 0x1C)))
    }
}
