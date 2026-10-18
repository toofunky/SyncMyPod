import AppKit
import AVFoundation
import Observation
import SwiftData

/// Plays songs from a queue, or a single podcast episode from where it was left.
@Observable
final class MusicPlayerModel {
    /// Skipping back this far into a song restarts it instead of going to the previous one.
    private static let restartThreshold = 3.0
    private static let progressInterval = Duration.milliseconds(250)
    /// How often a playing episode's position is saved, so quitting or a crash loses little.
    private static let positionSaveInterval = 10.0
    static let episodeSkipBackward = 15.0
    static let episodeSkipForward = 30.0

    private(set) var queue = PlaybackQueue()
    private(set) var currentEpisode: NowPlayingEpisode?
    private(set) var isPlaying = false
    private(set) var isShuffled = false
    private(set) var isRepeating = false
    /// Seconds into the current song or episode, refreshed while it plays.
    private(set) var elapsed: TimeInterval = 0

    @ObservationIgnored private let player = AVPlayer()
    @ObservationIgnored private var endObserver: Task<Void, Never>?
    @ObservationIgnored private var progressUpdates: Task<Void, Never>?
    @ObservationIgnored private var episodeContext: ModelContext?
    @ObservationIgnored private var savedPosition: TimeInterval = 0

    init() {
        _ = NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil,
                                                   queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.saveEpisodePosition() }
        }
    }

    var currentTrack: LibraryTrack? { queue.current }
    var hasCurrentItem: Bool { currentTrack != nil || currentEpisode != nil }
    var currentDuration: TimeInterval { currentEpisode?.duration ?? currentTrack?.duration ?? 0 }
    var canSkipForward: Bool { currentEpisode != nil || queue.hasNext || (isRepeating && currentTrack != nil) }

    func isCurrent(_ track: LibraryTrack) -> Bool {
        currentTrack?.filePath == track.filePath
    }

    func isCurrent(_ episode: PodcastEpisode) -> Bool {
        currentEpisode?.id == episode.persistentModelID
    }

    func play(_ tracks: [LibraryTrack], startingAt index: Int) {
        guard tracks.indices.contains(index) else { return }
        leaveEpisode()
        queue = PlaybackQueue(tracks: tracks, startingAt: index, shuffled: isShuffled)
        loadCurrentTrack()
        resume()
    }

    /// Picks up where the episode was left, or carries on if it's the one already loaded.
    func play(_ episode: PodcastEpisode) {
        guard !isCurrent(episode) else { return resume() }
        guard let nowPlaying = NowPlayingEpisode(episode) else { return }
        leaveEpisode()
        queue = PlaybackQueue()
        currentEpisode = nowPlaying
        episodeContext = episode.modelContext
        savedPosition = episode.playbackPosition
        load(nowPlaying.fileURL, at: episode.playbackPosition)
        if nowPlaying.duration <= 0 { loadDuration(of: nowPlaying.fileURL) }
        resume()
    }

    /// Stops if one of these episodes is playing, as when its download is removed.
    func stop(_ episodes: [PodcastEpisode]) {
        guard episodes.contains(where: isCurrent) else { return }
        pause()
        leaveEpisode()
        load(nil)
    }

    func togglePlayPause() {
        isPlaying ? pause() : resume()
    }

    func skipForward() {
        if currentEpisode != nil { return seek(to: elapsed + Self.episodeSkipForward) }
        guard queue.advance(wrapping: isRepeating) else { return }
        loadCurrentTrack()
    }

    func skipBackward() {
        if currentEpisode != nil { return seek(to: max(elapsed - Self.episodeSkipBackward, 0)) }
        if elapsed > Self.restartThreshold || !queue.retreat(wrapping: isRepeating) {
            seek(to: 0)
        } else {
            loadCurrentTrack()
        }
    }

    func seek(to seconds: TimeInterval) {
        elapsed = seconds
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }

    func toggleShuffle() {
        isShuffled.toggle()
        queue.setShuffled(isShuffled)
    }

    func toggleRepeat() {
        isRepeating.toggle()
    }

    private func resume() {
        guard hasCurrentItem else { return }
        player.play()
        isPlaying = true
        trackProgress()
    }

    private func pause() {
        player.pause()
        isPlaying = false
        progressUpdates?.cancel()
        saveEpisodePosition()
    }

    private func trackProgress() {
        progressUpdates?.cancel()
        progressUpdates = Task { [weak self] in
            while !Task.isCancelled {
                self?.updateElapsed()
                try? await Task.sleep(for: Self.progressInterval)
            }
        }
    }

    private func updateElapsed() {
        let seconds = player.currentTime().seconds
        elapsed = seconds.isFinite ? seconds : 0
        if currentEpisode != nil, abs(elapsed - savedPosition) >= Self.positionSaveInterval {
            saveEpisodePosition()
        }
    }

    private func saveEpisodePosition() {
        guard let id = currentEpisode?.id, let context = episodeContext,
              let episode: PodcastEpisode = context.registeredModel(for: id), !episode.isDeleted else { return }
        episode.playbackPosition = elapsed
        savedPosition = elapsed
        try? context.save()
    }

    private func leaveEpisode() {
        saveEpisodePosition()
        currentEpisode = nil
        episodeContext = nil
    }

    /// Feeds often leave out the duration, so read it from the file.
    private func loadDuration(of url: URL) {
        Task { [weak self] in
            guard let duration = try? await AVURLAsset(url: url).load(.duration), duration.seconds.isFinite,
                  self?.currentEpisode?.fileURL == url else { return }
            self?.currentEpisode?.duration = duration.seconds
        }
    }

    private func loadCurrentTrack() {
        load(currentTrack.map { URL(filePath: $0.filePath) })
    }

    /// The player pauses itself when an item ends, so restart it if we were playing.
    private func load(_ url: URL?, at start: TimeInterval = 0) {
        endObserver?.cancel()
        elapsed = start
        guard let url else { return player.replaceCurrentItem(with: nil) }
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        if start > 0 { player.seek(to: CMTime(seconds: start, preferredTimescale: 600)) }
        if isPlaying { player.play() }
        endObserver = Task { [weak self] in
            let ends = NotificationCenter.default.notifications(named: AVPlayerItem.didPlayToEndTimeNotification,
                                                                object: item)
            for await _ in ends {
                self?.trackDidEnd()
            }
        }
    }

    /// An episode has no queue to advance through, so it stops like the last song does, saved as back at the start.
    private func trackDidEnd() {
        if queue.advance(wrapping: isRepeating) {
            loadCurrentTrack()
        } else {
            seek(to: 0)
            pause()
        }
    }
}
