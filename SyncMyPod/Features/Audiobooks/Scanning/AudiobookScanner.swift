import Foundation
import SwiftData

/// Brings the audiobook files up to date with the folder, reading only new and changed files, then regroups them
/// into books. Books keep their listening position as long as their folder does.
@ModelActor
actor AudiobookScanner {
    typealias ProgressHandler = @MainActor @Sendable (LibraryScanProgress) -> Void

    private static let saveInterval = 100
    private static let progressInterval = 25
    private static let maxConcurrentReads = 3

    private let enumerator = AudioFileEnumerator(fileExtensions: AudioFileEnumerator.audiobookExtensions)
    private let reader = AudioMetadataReader()

    func scan(folderURL: URL, progress: @escaping ProgressHandler) async throws -> LibraryScanSummary {
        let files = try enumerator.files(in: folderURL)
        var unseen = try existingFilesByPath()
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
        try regroup(rootPath: Self.canonicalPath(of: folderURL))
        return summary
    }

    /// The enumerator's paths have symlinks resolved, such as /var to /private/var, so the root must too.
    private static func canonicalPath(of url: URL) -> String {
        (try? url.resourceValues(forKeys: [.canonicalPathKey]).canonicalPath) ?? url.path(percentEncoded: false)
    }

    private func regroup(rootPath: String) throws {
        let files = try modelContext.fetch(FetchDescriptor<AudiobookFile>())
        let filesByPath = Dictionary(files.map { ($0.filePath, $0) }, uniquingKeysWith: { first, _ in first })
        let summaries = files.map { AudiobookFileSummary(path: $0.filePath, album: $0.album) }
        var unseenBooks = try existingBooksByPath()
        for group in AudiobookGrouper(rootPath: rootPath).groups(for: summaries) {
            let book = unseenBooks.removeValue(forKey: group.key) ?? insertBook(for: group)
            book.apply(group, files: group.filePaths.compactMap { filesByPath[$0] })
        }
        unseenBooks.values.forEach(modelContext.delete)
        if modelContext.hasChanges { try modelContext.save() }
    }

    private func insertBook(for group: AudiobookGroup) -> Audiobook {
        let book = Audiobook(folderPath: group.key, title: group.fallbackTitle)
        modelContext.insert(book)
        return book
    }

    private func existingFilesByPath() throws -> [String: AudiobookFile] {
        let files = try modelContext.fetch(FetchDescriptor<AudiobookFile>())
        return Dictionary(files.map { ($0.filePath, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private func existingBooksByPath() throws -> [String: Audiobook] {
        let books = try modelContext.fetch(FetchDescriptor<Audiobook>())
        return Dictionary(books.map { ($0.folderPath, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private func filesNeedingRead(_ files: [ScannedAudioFile], unseen: inout [String: AudiobookFile],
                                  summary: inout LibraryScanSummary) -> [ScannedAudioFile] {
        files.filter { file in
            guard let existing = unseen[file.path], existing.matches(file) else { return true }
            unseen.removeValue(forKey: file.path)
            summary.record(.unchanged)
            return false
        }
    }

    private func readAndApply(_ files: [ScannedAudioFile], unseen: inout [String: AudiobookFile],
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
                       existing: AudiobookFile?) -> LibraryScanOutcome {
        guard let metadata else {
            guard let existing else { return .skipped }
            modelContext.delete(existing)
            return .removed
        }
        if let existing {
            existing.update(file: file, metadata: metadata)
            return .updated
        }
        let audiobookFile = AudiobookFile(filePath: file.path)
        audiobookFile.update(file: file, metadata: metadata)
        modelContext.insert(audiobookFile)
        return .added
    }
}
