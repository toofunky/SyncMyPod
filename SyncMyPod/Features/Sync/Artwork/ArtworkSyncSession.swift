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

    /// Renders and stores the file's embedded cover, reusing identical art already stored for
    /// `albumTracks`; `nil` when there's no cover or it can't be decoded.
    mutating func prepare(coverFrom url: URL, albumTracks: [UInt64] = []) async throws -> PreparedArtwork? {
        guard let cover = try? await CoverArtReader().read(url) else { return nil }
        let renders = formats.compactMap { ArtworkRenderer.render(cover.image, as: $0) }
        guard renders.count == formats.count else { return nil }
        var candidates: [[ArtworkThumbnail]] = []
        for thumbnails in editor.thumbnails(forTracks: albumTracks, formats: formats) where !candidates.contains(thumbnails) {
            candidates.append(thumbnails)
        }
        let thumbnails = try pixels.store(renders, reusing: candidates)
        let link = ITunesTrackArtwork(imageID: editor.allocateImageID(), sourceByteCount: cover.byteCount)
        return PreparedArtwork(trackArtwork: link, thumbnails: thumbnails)
    }

    mutating func attach(_ prepared: PreparedArtwork, toTrack databaseID: UInt64) {
        editor.addImage(id: prepared.trackArtwork.imageID, trackDatabaseID: databaseID,
                        thumbnails: prepared.thumbnails)
        hasChanges = true
    }

    mutating func removeImages(forTracks databaseIDs: Set<UInt64>) {
        if editor.removeImages(forTracks: databaseIDs) { hasChanges = true }
    }

    func save() throws {
        guard hasChanges else { return }
        try store.save(editor.serialized())
    }

    /// Frees space left by removed covers. Runs after the sync is committed; failures leave the
    /// previous, still-valid files in place.
    mutating func compactIfWasteful() {
        let compactor = ArtworkCompactor(directoryURL: store.fileURL.deletingLastPathComponent())
        var compacted = editor
        var staged: [(url: URL, format: ArtworkFormat)] = []
        do {
            for format in formats {
                guard let offsets = compacted.referencedOffsets(for: format),
                      let mapping = compactor.compactionMapping(for: format, referenced: offsets) else { continue }
                staged.append((try compactor.stage(format, mapping: mapping), format))
                compacted.remapOffsets(for: format, mapping)
            }
            guard !staged.isEmpty else { return }
            try store.save(compacted.serialized())
            editor = compacted
            for file in staged { try compactor.commit(file.url, for: file.format) }
        } catch {
            staged.forEach { try? FileManager.default.removeItem(at: $0.url) }
        }
    }

    func rollBack() {
        pixels.rollBack()
        if hasChanges { try? store.restore(original) }
    }
}
