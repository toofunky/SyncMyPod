import Foundation
import Observation
import SwiftData

/// Scans the audiobook folder into books in the background.
@Observable
@MainActor
final class AudiobooksModel {
    private(set) var state = LibraryScanState.idle

    @ObservationIgnored private var scanTask: Task<Void, Never>?

    var isScanning: Bool {
        if case .scanning = state { true } else { false }
    }

    func rescan(_ folderURL: URL, in context: ModelContext) {
        scanTask?.cancel()
        scanTask = Task { await scan(folderURL, container: context.container) }
    }

    func cancelScan() {
        scanTask?.cancel()
    }

    private func scan(_ folderURL: URL, container: ModelContainer) async {
        do {
            state = .scanning(LibraryScanProgress(completed: 0, total: 0))
            let summary = try await Self.runScanner(in: container, folderURL: folderURL) { [weak self] in
                self?.state = .scanning($0)
            }
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
        try await AudiobookScanner(modelContainer: container).scan(folderURL: folderURL, progress: progress)
    }
}
