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
    var lyrics = ""
    var errorMessage: String?
    private(set) var originals: [TagField: TagFieldValue] = [:]
    /// `nil` until read from the file, and always with several songs selected.
    private(set) var originalLyrics: String?
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

    /// Lyrics are edited one song at a time, so a whole album can't get the same lyrics by mistake.
    var canEditLyrics: Bool { tracks.count == 1 }

    var lyricsEdit: String? {
        guard let originalLyrics, lyrics != originalLyrics else { return nil }
        return lyrics
    }

    var hasChanges: Bool { !edits.isEmpty || artworkChange != .keep || lyricsEdit != nil }

    var displayedArtwork: TagArtworkPreview {
        switch artworkChange {
        case .keep: originalArtwork
        case .remove: .none
        case .replace: replacementArtwork.map(TagArtworkPreview.image) ?? .none
        }
    }

    /// An empty sort field shows what the song sorts by: its name without a leading "A", "An" or "The".
    func placeholder(for field: TagField) -> String {
        if originals[field] == .mixed { return "Mixed" }
        guard let sorted = field.sortedField else { return "" }
        return values[sorted, default: ""].sortName
    }

    func revert() {
        values = originals.mapValues(\.commonValue)
        lyrics = originalLyrics ?? ""
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

    /// Reads the file even when the library notes no lyrics, since older scans missed FLAC's.
    func loadLyrics() async {
        guard canEditLyrics, let track = tracks.first else { return }
        let text = (try? await EmbeddedLyricsReader().read(URL(filePath: track.filePath))) ?? ""
        originalLyrics = text
        lyrics = text
    }

    /// Writes one file at a time, since the library lives on a spinning drive.
    func save(in context: ModelContext) async {
        isSaving = true
        defer { isSaving = false }
        let edits = edits, artwork = artworkChange, lyricsEdit = lyricsEdit
        do {
            for track in tracks { try await save(track, edits: edits, artwork: artwork, lyrics: lyricsEdit) }
            try context.save()
            if let lyricsEdit { originalLyrics = lyricsEdit }
            reloadValues()
            await loadArtwork()
        } catch {
            try? context.save()
            errorMessage = error.localizedDescription
        }
    }

    private func save(_ track: LibraryTrack, edits: [TagField: String], artwork: ArtworkChange,
                      lyrics: String?) async throws {
        let url = URL(filePath: track.filePath)
        let changes = TagChanges(edits: edits, artwork: artwork, lyrics: lyrics, applyingTo: track)
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
