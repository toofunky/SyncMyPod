import Foundation

/// Adds cover images to a parsed ArtworkDB tree, keeping existing records byte-identical.
nonisolated struct ArtworkDBEditor {
    private static let nextImageIDOffset = 0x1C

    private(set) var root: ITunesDBRecord
    private var nextImageID: UInt32

    init(root: ITunesDBRecord) {
        self.root = root
        let highestExisting = Self.list(in: root, .images)?.children.map { $0.uint32(at: 0x10) }.max()
        nextImageID = max(root.uint32(at: Self.nextImageIDOffset), highestExisting.map { $0 + 1 } ?? 0,
                          ArtworkRecordBuilder.firstImageID)
    }

    static func empty(formats: [ArtworkFormat]) -> ArtworkDBEditor {
        ArtworkDBEditor(root: ArtworkRecordBuilder.emptyDatabase(formats: formats))
    }

    mutating func allocateImageID() -> UInt32 {
        defer { nextImageID += 1 }
        return nextImageID
    }

    mutating func addImage(id: UInt32, trackDatabaseID: UInt64, thumbnails: [ArtworkThumbnail]) {
        let mhii = ArtworkRecordBuilder.image(id: id, trackDatabaseID: trackDatabaseID, thumbnails: thumbnails)
        modifyList(.images) { $0.children.append(mhii) }
        for format in thumbnails.map(\.format) where !listsFile(for: format) {
            modifyList(.files) { $0.children.append(ArtworkRecordBuilder.fileEntry(format)) }
        }
    }

    /// Removes every image linked to the given tracks. Their pixels stay in the `.ithmb` files until compacted.
    mutating func removeImages(forTracks databaseIDs: Set<UInt64>) -> Bool {
        var removedAny = false
        modifyList(.images) { list in
            let before = list.children.count
            list.children.removeAll { databaseIDs.contains($0.uint64(at: 0x14)) }
            removedAny = list.children.count != before
        }
        return removedAny
    }

    /// Thumbnails of the image linked to each given track, for reusing a cover that's already on the iPod.
    func thumbnails(forTracks databaseIDs: [UInt64], formats: [ArtworkFormat]) -> [[ArtworkThumbnail]] {
        let images = Self.list(in: root, .images)?.children ?? []
        return databaseIDs.compactMap { databaseID in
            images.first { $0.uint64(at: 0x14) == databaseID }
                .map { ArtworkThumbnailParser.thumbnails(in: $0, formats: formats) }
        }
    }

    /// Offsets referenced in the format's `_1` file, or `nil` if some image uses another file for that format.
    func referencedOffsets(for format: ArtworkFormat) -> Set<UInt32>? {
        let records = Self.list(in: root, .images)?.children.flatMap(Self.thumbnailRecords) ?? []
        let matching = records.filter { $0.uint32(at: 0x10) == format.id }
        guard matching.allSatisfy({ ArtworkThumbnailParser.fileName(of: $0) == ":\(format.fileName)" }) else { return nil }
        return Set(matching.map { $0.uint32(at: 0x14) })
    }

    mutating func remapOffsets(for format: ArtworkFormat, _ mapping: [UInt32: UInt32]) {
        modifyList(.images) { list in
            for image in list.children.indices {
                for mhod in list.children[image].children.indices {
                    for index in list.children[image].children[mhod].children.indices {
                        Self.remap(&list.children[image].children[mhod].children[index], format: format, mapping)
                    }
                }
            }
        }
    }

    func serialized() -> Data {
        var updated = root
        updated.set(nextImageID, at: Self.nextImageIDOffset)
        return updated.serialized()
    }

    private static func thumbnailRecords(of image: ITunesDBRecord) -> [ITunesDBRecord] {
        image.children.flatMap { $0.children.filter { $0.tag == "mhni" } }
    }

    private static func remap(_ mhni: inout ITunesDBRecord, format: ArtworkFormat, _ mapping: [UInt32: UInt32]) {
        guard mhni.tag == "mhni", mhni.uint32(at: 0x10) == format.id,
              let offset = mapping[mhni.uint32(at: 0x14)] else { return }
        mhni.set(offset, at: 0x14)
    }

    private func listsFile(for format: ArtworkFormat) -> Bool {
        Self.list(in: root, .files)?.children.contains { $0.uint32(at: 0x10) == format.id } ?? false
    }

    private mutating func modifyList(_ section: ArtworkDBSectionType, _ change: (inout ITunesDBRecord) -> Void) {
        guard let index = root.children.firstIndex(where: { Self.isSection($0, section) }),
              !root.children[index].children.isEmpty else { return }
        change(&root.children[index].children[0])
    }

    private static func list(in root: ITunesDBRecord, _ section: ArtworkDBSectionType) -> ITunesDBRecord? {
        root.children.first { isSection($0, section) }?.children.first
    }

    private static func isSection(_ record: ITunesDBRecord, _ section: ArtworkDBSectionType) -> Bool {
        record.tag == "mhsd" && UInt16(truncatingIfNeeded: record.recordType) == section.rawValue
    }
}
