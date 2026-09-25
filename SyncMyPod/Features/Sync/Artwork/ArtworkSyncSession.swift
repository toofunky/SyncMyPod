import Foundation

/// Stores covers for the tracks added in one sync and writes the ArtworkDB, or undoes it all on failure.
nonisolated struct ArtworkSyncSession {
    let formats: [ArtworkFormat]

    private let store: DatabaseFileStore
    private let original: Data?
    private var editor: ArtworkDBEditor
    private var pixels: ArtworkPixelStore
    private var hasChanges = false

    init(volumeURL: URL, formats: [ArtworkFormat]) throws {
        store = .artworkDB(onVolume: volumeURL)
        original = store.exists ? try Data(contentsOf: store.fileURL) : nil
        editor = try original.map { data in
            ArtworkDBEditor(root: try ITunesDBRecordParser(data: data, layout: .artworkDB).parse())
        } ?? .empty(formats: formats)
        pixels = ArtworkPixelStore(directoryURL: store.fileURL.deletingLastPathComponent())
        self.formats = formats
    }

    /// Renders and stores the file's embedded cover; `nil` when there's none or it can't be decoded.
    mutating func prepare(coverFrom url: URL) async throws -> PreparedArtwork? {
        guard let cover = try? await CoverArtReader().read(url) else { return nil }
        let renders = formats.compactMap { ArtworkRenderer.render(cover.image, as: $0) }
        guard renders.count == formats.count else { return nil }
        let thumbnails = try pixels.store(renders)
        let link = ITunesTrackArtwork(imageID: editor.allocateImageID(), sourceByteCount: cover.byteCount)
        return PreparedArtwork(trackArtwork: link, thumbnails: thumbnails)
    }

    mutating func attach(_ prepared: PreparedArtwork, toTrack databaseID: UInt64) {
        editor.addImage(id: prepared.trackArtwork.imageID, trackDatabaseID: databaseID,
                        thumbnails: prepared.thumbnails)
        hasChanges = true
    }

    func save() throws {
        guard hasChanges else { return }
        try store.save(editor.serialized())
    }

    func rollBack() {
        pixels.rollBack()
        if hasChanges { try? store.restore(original) }
    }
}
