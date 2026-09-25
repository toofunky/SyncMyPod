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

    func serialized() -> Data {
        var updated = root
        updated.set(nextImageID, at: Self.nextImageIDOffset)
        return updated.serialized()
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
