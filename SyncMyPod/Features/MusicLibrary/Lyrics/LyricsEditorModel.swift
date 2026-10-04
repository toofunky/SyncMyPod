import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class LyricsEditorModel {
    let track: LibraryTrack
    var text = ""
    var errorMessage: String?
    private(set) var hasFile = false
    private(set) var isLoaded = false
    private(set) var isSaving = false

    init(track: LibraryTrack) {
        self.track = track
    }

    var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// Stays unloaded on failure, so a file that couldn't be read is never overwritten.
    func load() async {
        do {
            let lyrics = try await LyricsFile.read(forSongAt: track.filePath)
            text = lyrics ?? ""
            hasFile = lyrics != nil
            isLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Returns whether the file was written, so the editor can close.
    func save() async -> Bool {
        let text = text, path = track.filePath
        return await update(hasLyrics: true) { try await LyricsFile.write(text, forSongAt: path) }
    }

    func delete() async -> Bool {
        let path = track.filePath
        return await update(hasLyrics: false) { try await LyricsFile.remove(forSongAt: path) }
    }

    private func update(hasLyrics: Bool, _ operation: () async throws -> Void) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        do {
            try await operation()
            track.hasLyrics = hasLyrics
            try track.modelContext?.save()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
