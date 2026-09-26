import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class MusicLibraryModel {
    private(set) var state = LibraryScanState.idle

    @ObservationIgnored private var scanTask: Task<Void, Never>?

    var isScanning: Bool {
        if case .scanning = state { true } else { false }
    }

    func chooseFolder(_ url: URL, in context: ModelContext) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            try context.delete(model: LibraryFolder.self)
            context.insert(try LibraryFolder.make(for: url))
            try context.save()
            rescan(in: context)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func rescan(in context: ModelContext) {
        guard let folder = try? context.fetch(FetchDescriptor<LibraryFolder>()).first else { return }
        scanTask?.cancel()
        scanTask = Task { await scan(folder, container: context.container) }
    }

    func cancelScan() {
        scanTask?.cancel()
    }

    private func scan(_ folder: LibraryFolder, container: ModelContainer) async {
        do {
            let url = try folder.resolveURL()
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            state = .scanning(LibraryScanProgress(completed: 0, total: 0))
            let summary = try await Self.runScanner(in: container, folderURL: url) { [weak self] in
                self?.state = .scanning($0)
            }
            folder.lastScanDate = .now
            state = .finished(summary)
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    @concurrent
    private static func runScanner(in container: ModelContainer, folderURL: URL,
                                   progress: @escaping @MainActor @Sendable (LibraryScanProgress) -> Void)
        async throws -> LibraryScanSummary {
        try await LibraryScanner(modelContainer: container).scan(folderURL: folderURL, progress: progress)
    }
}
