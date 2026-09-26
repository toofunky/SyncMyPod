import Foundation
import SwiftData

@ModelActor
actor LibraryScanner {
    typealias ProgressHandler = @MainActor @Sendable (LibraryScanProgress) -> Void

    private static let saveInterval = 100
    private static let progressInterval = 25
    private static let maxConcurrentReads = 3

    private let enumerator = AudioFileEnumerator()
    private let reader = AudioMetadataReader()

    func scan(folderURL: URL, progress: @escaping ProgressHandler) async throws -> LibraryScanSummary {
        let files = try enumerator.files(in: folderURL)
        var unseen = try existingTracksByPath()
        var summary = LibraryScanSummary()
        let changed = filesNeedingRead(files, unseen: &unseen, summary: &summary)
        let unchangedCount = files.count - changed.count
        await progress(LibraryScanProgress(completed: unchangedCount, total: files.count))
        try await readAndApply(changed, unseen: &unseen, summary: &summary) { completed in
            guard completed.isMultiple(of: Self.progressInterval) || completed == changed.count else { return }
            await progress(LibraryScanProgress(completed: unchangedCount + completed, total: files.count))
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

    private func filesNeedingRead(_ files: [ScannedAudioFile], unseen: inout [String: LibraryTrack],
                                  summary: inout LibraryScanSummary) -> [ScannedAudioFile] {
        files.filter { file in
            guard let existing = unseen[file.path], existing.matches(file) else { return true }
            unseen.removeValue(forKey: file.path)
            summary.record(.unchanged)
            return false
        }
    }

    private func readAndApply(_ files: [ScannedAudioFile], unseen: inout [String: LibraryTrack],
                              summary: inout LibraryScanSummary,
                              onCompleted: (Int) async -> Void) async throws {
        let reader = self.reader
        try await withThrowingTaskGroup(of: (ScannedAudioFile, AudioFileMetadata?).self) { group in
            var pending = files.makeIterator()
            for _ in 0..<Self.maxConcurrentReads {
                guard let file = pending.next() else { break }
                group.addTask { (file, try? await reader.read(file.url)) }
            }
            var completed = 0
            while let (file, metadata) = try await group.next() {
                try Task.checkCancellation()
                summary.record(apply(metadata, to: file, existing: unseen.removeValue(forKey: file.path)))
                completed += 1
                if completed.isMultiple(of: Self.saveInterval) { try modelContext.save() }
                await onCompleted(completed)
                if let next = pending.next() { group.addTask { (next, try? await reader.read(next.url)) } }
            }
        }
    }

    private func apply(_ metadata: AudioFileMetadata?, to file: ScannedAudioFile,
                       existing: LibraryTrack?) -> LibraryScanOutcome {
        guard let metadata else {
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
