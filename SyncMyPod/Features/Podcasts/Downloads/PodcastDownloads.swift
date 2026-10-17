import Foundation
import Observation
import SwiftData

/// Downloads and removes episodes, a few at a time, app-wide so downloads carry on when the view changes.
@MainActor
@Observable
final class PodcastDownloads {
    static let maximumConcurrent = 3

    private(set) var states: [PersistentIdentifier: PodcastDownloadState] = [:]
    /// The last failure for each episode, cleared when it's downloaded again.
    private(set) var errors: [PersistentIdentifier: String] = [:]
    @ObservationIgnored private var queue: [(episode: PodcastEpisode, folder: URL, context: ModelContext)] = []
    @ObservationIgnored private var tasks: [PersistentIdentifier: Task<Void, Never>] = [:]

    func state(of episode: PodcastEpisode) -> PodcastDownloadState? { states[episode.persistentModelID] }

    func error(for episode: PodcastEpisode) -> String? { errors[episode.persistentModelID] }

    func download(_ episodes: [PodcastEpisode], into folder: URL, context: ModelContext) {
        for episode in episodes where !episode.isDownloaded {
            let id = episode.persistentModelID
            guard states[id] == nil, tasks[id] == nil else { continue }
            states[id] = .queued
            errors[id] = nil
            queue.append((episode, folder, context))
        }
        startQueued()
    }

    func cancel(_ episodes: [PodcastEpisode]) {
        let ids = Set(episodes.map(\.persistentModelID))
        queue.removeAll { ids.contains($0.episode.persistentModelID) }
        for id in ids {
            tasks[id]?.cancel()
            states[id] = nil
        }
    }

    /// Moves the files to the Trash, so a mistaken removal can be undone in Finder.
    func removeDownloads(of episodes: [PodcastEpisode], context: ModelContext) {
        for episode in episodes {
            guard let url = episode.downloadedFileURL else { continue }
            let exists = FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
            if !exists || (try? FileManager.default.trashItem(at: url, resultingItemURL: nil)) != nil {
                episode.downloadedFilePath = nil
            }
            errors[episode.persistentModelID] = nil
        }
        try? context.save()
    }

    /// Forgets downloads whose files were deleted or moved outside the app.
    func forgetMissingFiles(of podcast: Podcast, context: ModelContext) {
        let missing = podcast.episodes.filter { episode in
            episode.downloadedFilePath.map { !FileManager.default.fileExists(atPath: $0) } ?? false
        }
        guard !missing.isEmpty else { return }
        missing.forEach { $0.downloadedFilePath = nil }
        try? context.save()
    }

    /// Reads the codec and audio details of downloads made before they were recorded, which an iPod needs.
    func readMissingAudioDetails(of podcasts: [Podcast], context: ModelContext) async {
        let episodes = podcasts.flatMap(\.episodes).filter { $0.isDownloaded && $0.codecRawValue == nil }
        guard !episodes.isEmpty else { return }
        for episode in episodes {
            guard let url = episode.downloadedFileURL,
                  let metadata = try? await AudioMetadataReader().read(url) else { continue }
            episode.apply(metadata)
        }
        try? context.save()
    }

    private func startQueued() {
        while tasks.count < Self.maximumConcurrent, !queue.isEmpty {
            let pending = queue.removeFirst()
            let id = pending.episode.persistentModelID
            states[id] = .downloading(nil)
            tasks[id] = Task {
                await run(pending.episode, into: pending.folder, context: pending.context)
                finish(id)
            }
        }
    }

    private func finish(_ id: PersistentIdentifier) {
        tasks[id] = nil
        states[id] = nil
        startQueued()
    }

    private func run(_ episode: PodcastEpisode, into folder: URL, context: ModelContext) async {
        let id = episode.persistentModelID
        guard let job = Self.job(for: episode) else {
            errors[id] = "The episode's audio address isn't valid."
            return
        }
        do {
            let result = try await job.run(into: folder) { [weak self] fraction in
                Task { @MainActor in self?.setProgress(fraction, for: id) }
            }
            episode.downloadedFilePath = result.fileURL.path(percentEncoded: false)
            episode.downloadedAt = .now
            episode.byteCount = result.byteCount
            if let metadata = result.metadata { episode.apply(metadata) }
            try? context.save()
        } catch {
            if !Task.isCancelled { errors[id] = error.localizedDescription }
        }
    }

    private func setProgress(_ fraction: Double?, for id: PersistentIdentifier) {
        guard case .downloading = states[id] else { return }
        states[id] = .downloading(fraction)
    }

    private static func job(for episode: PodcastEpisode) -> PodcastDownloadJob? {
        guard let podcast = episode.podcast, let source = URL(string: episode.enclosureURL) else { return nil }
        let path = PodcastEpisodeFileNamer.relativePath(show: podcast.title, title: episode.title,
                                                        publishedAt: episode.publishedAt, enclosure: source,
                                                        mimeType: episode.enclosureType)
        let tags = PodcastEpisodeTags(title: episode.title, show: podcast.title, author: podcast.author,
                                      publishedAt: episode.publishedAt, episodeNumber: episode.episodeNumber,
                                      showArtwork: podcast.artworkData)
        return PodcastDownloadJob(source: source, relativePath: path, tags: tags)
    }
}
