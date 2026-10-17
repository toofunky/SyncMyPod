import Foundation
import Synchronization

/// Reports a download's progress in whole-percent steps, or `nil` while the server hasn't said how large it is.
nonisolated final class PodcastDownloadProgressDelegate: NSObject, URLSessionTaskDelegate, Sendable {
    private let onProgress: @Sendable (Double?) -> Void
    private let observation = Mutex<NSKeyValueObservation?>(nil)
    private let lastPercent = Mutex(-1)

    init(onProgress: @escaping @Sendable (Double?) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        let observer = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            self?.report(progress)
        }
        observation.withLock { $0 = observer }
    }

    private func report(_ progress: Progress) {
        guard progress.totalUnitCount > 0 else { return onProgress(nil) }
        let percent = Int(progress.fractionCompleted * 100)
        let changed = lastPercent.withLock { last in
            defer { last = percent }
            return last != percent
        }
        if changed { onProgress(Double(percent) / 100) }
    }
}
