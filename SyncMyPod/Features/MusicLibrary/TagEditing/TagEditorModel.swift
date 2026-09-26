import CoreGraphics
import Foundation
import ImageIO
import Observation
import SwiftData

@Observable
@MainActor
final class TagEditorModel {
    let tracks: [LibraryTrack]
    var values: [TagField: String] = [:]
    var errorMessage: String?
    private(set) var originals: [TagField: TagFieldValue] = [:]
    private(set) var originalArtwork = TagArtworkPreview.none
    private(set) var artworkChange = ArtworkChange.keep
    private(set) var replacementArtwork: CGImage?
    private(set) var isSaving = false

    @ObservationIgnored private let writer = TagWriter()

    init(tracks: [LibraryTrack]) {
        self.tracks = tracks
        reloadValues()
    }

    var edits: [TagField: String] {
        values.filter { field, text in originals[field]?.isEdited(by: text) ?? false }
    }

    var hasChanges: Bool { !edits.isEmpty || artworkChange != .keep }

    var displayedArtwork: TagArtworkPreview {
        switch artworkChange {
        case .keep: originalArtwork
        case .remove: .none
        case .replace: replacementArtwork.map(TagArtworkPreview.image) ?? .none
        }
    }

    func placeholder(for field: TagField) -> String {
        originals[field] == .mixed ? "Mixed" : ""
    }

    func revert() {
        values = originals.mapValues(\.commonValue)
        artworkChange = .keep
        replacementArtwork = nil
    }

    /// Returns `false` for anything but a JPEG or PNG.
    @discardableResult
    func replaceArtwork(with data: Data) -> Bool {
        guard ArtworkImageType(data: data) != nil,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return false }
        artworkChange = .replace(data)
        replacementArtwork = image
        return true
    }

    func removeArtwork() {
        artworkChange = .remove
        replacementArtwork = nil
    }

    /// Shows the cover when every selected song has the same one.
    func loadArtwork() async {
        let fingerprints = Set(tracks.map(\.artworkFingerprint))
        guard fingerprints.count == 1, let track = tracks.first else { return originalArtwork = .mixed }
        guard track.artworkFingerprint != nil else { return originalArtwork = .none }
        let art = try? await CoverArtReader().read(URL(filePath: track.filePath))
        originalArtwork = art.map { .image($0.image) } ?? .none
    }

    /// Writes one file at a time, since the library lives on a spinning drive.
    func save(in context: ModelContext) async {
        isSaving = true
        defer { isSaving = false }
        let edits = edits, artwork = artworkChange
        do {
            for track in tracks { try await save(track, edits: edits, artwork: artwork) }
            try context.save()
            reloadValues()
            await loadArtwork()
        } catch {
            try? context.save()
            errorMessage = error.localizedDescription
        }
    }

    private func save(_ track: LibraryTrack, edits: [TagField: String], artwork: ArtworkChange) async throws {
        let url = URL(filePath: track.filePath)
        let changes = TagChanges(edits: edits, artwork: artwork, applyingTo: track)
        try await writer.write(changes, to: url, codec: track.codec)
        try await track.refresh(from: url)
    }

    private func reloadValues() {
        originals = Dictionary(uniqueKeysWithValues: TagField.allCases.map { field in
            (field, TagFieldValue(tracks.map(field.value(of:))))
        })
        revert()
    }
}
