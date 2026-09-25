import Foundation
import SwiftData

@ModelActor
actor LibraryScanner {
    private static let saveInterval = 100

    private let enumerator = AudioFileEnumerator()
    private let reader = AudioMetadataReader()

    func scan(folderURL: URL,
              progress: @escaping @MainActor @Sendable (LibraryScanProgress) -> Void)
        async throws -> LibraryScanSummary {
        let files = try enumerator.files(in: folderURL)
        var unseen = try existingTracksByPath()
        var summary = LibraryScanSummary()
        for (index, file) in files.enumerated() {
            try Task.checkCancellation()
            summary.record(await process(file, existing: unseen.removeValue(forKey: file.path)))
            if (index + 1).isMultiple(of: Self.saveInterval) { try modelContext.save() }
            await progress(LibraryScanProgress(completed: index + 1, total: files.count))
        }
        unseen.values.forEach(modelContext.delete)
        summary.removed += unseen.count
        try modelContext.save()
        return summary
    }

    private func existingTracksByPath() throws -> [String: LibraryTrack] {
        let tracks = try modelContext.fetch(FetchDescriptor<LibraryTrack>())
        return Dictionary(tracks.map { ($0.filePath, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private func process(_ file: ScannedAudioFile, existing: LibraryTrack?) async -> LibraryScanOutcome {
        if let existing, existing.matches(file) { return .unchanged }
        guard let metadata = try? await reader.read(file.url) else {
            guard let existing else { return .skipped }
            modelContext.delete(existing)
            return .removed
        }
        if let existing {
            existing.update(file: file, metadata: metadata)
            return .updated
        }
        let track = LibraryTrack(filePath: file.path)
        track.update(file: file, metadata: metadata)
        modelContext.insert(track)
        return .added
    }
}
