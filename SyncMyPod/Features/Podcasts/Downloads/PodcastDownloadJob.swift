import Foundation

/// Downloads one episode into the podcast folder and tags it, copied off the model so it runs off the main actor.
nonisolated struct PodcastDownloadJob: Sendable {
    let source: URL
    /// Relative to the podcast folder, as `PodcastEpisodeFileNamer` names it.
    let relativePath: String
    let tags: PodcastEpisodeTags

    @concurrent
    func run(into folder: URL, progress: @escaping @Sendable (Double?) -> Void) async throws -> PodcastDownloadResult {
        let delegate = PodcastDownloadProgressDelegate(onProgress: progress)
        let (temporaryURL, response) = try await URLSession.shared.download(from: source, delegate: delegate)
        defer { try? FileManager.default.removeItem(at: temporaryURL) }
        if let status = (response as? HTTPURLResponse)?.statusCode, !(200..<300).contains(status) {
            throw PodcastFeedError.httpStatus(status)
        }
        try Task.checkCancellation()
        let destination = try move(temporaryURL, into: folder)
        // An untaggable file is still worth keeping; it's only missing its show details.
        let metadata = try? await PodcastEpisodeTagger.tag(destination, with: tags)
        let size = try destination.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        return PodcastDownloadResult(fileURL: destination, byteCount: Int64(size), metadata: metadata)
    }

    private func move(_ temporaryURL: URL, into folder: URL) throws -> URL {
        let target = folder.appending(path: relativePath, directoryHint: .notDirectory)
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let destination = PodcastEpisodeFileNamer.unusedURL(for: target)
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
        return destination
    }
}
