import AppKit
import Observation
import SwiftData

/// Plays songs from a queue, or a podcast episode or audiobook from where it was left.
@Observable
final class MusicPlayerModel {
    /// Skipping back this far into a song restarts it instead of going to the previous one.
    private static let restartThreshold = 3.0
    private static let progressInterval = Duration.milliseconds(250)
    /// How often a playing episode's or book's position is saved, so quitting or a crash loses little.
    private static let positionSaveInterval = 10.0
    static let spokenSkipBackward = 15.0
    static let spokenSkipForward = 30.0

    private(set) var queue = PlaybackQueue()
    /// The episode or audiobook playing instead of a song.
    private(set) var currentSpoken: NowPlayingSpoken?
    private(set) var isPlaying = false
    private(set) var isShuffled = false
    private(set) var isRepeating = false
    /// Seconds into the current song or file, refreshed while it plays.
    private(set) var elapsed: TimeInterval = 0

    @ObservationIgnored private let engine = PlaybackEngine()
    @ObservationIgnored private var spokenContext: ModelContext?
    @ObservationIgnored private var savedPosition: TimeInterval = 0

    init() {
        _ = NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil,
                                                   queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.saveSpokenPosition() }
        }
    }

    var currentTrack: LibraryTrack? { queue.current }
    var hasCurrentItem: Bool { currentTrack != nil || currentSpoken != nil }
    var currentDuration: TimeInterval { currentSpoken?.currentFile.duration ?? currentTrack?.duration ?? 0 }
    var canSkipForward: Bool { currentSpoken != nil || queue.hasNext || (isRepeating && currentTrack != nil) }

    func play(_ tracks: [LibraryTrack], startingAt index: Int) {
        guard tracks.indices.contains(index) else { return }
        leaveSpoken()
        queue = PlaybackQueue(tracks: tracks, startingAt: index, shuffled: isShuffled)
        loadCurrentTrack()
        resume()
    }

    /// Picks up where the episode was left, or carries on if it's the one already loaded.
    func play(_ episode: PodcastEpisode) {
        guard !isCurrent(episode) else { return resume() }
        guard let nowPlaying = NowPlayingSpoken(episode) else { return }
        start(nowPlaying, at: episode.playbackPosition, context: episode.modelContext)
    }

    /// Starts the book at `file`, or carries on from where it was left. Starting at the file where listening
    /// stopped picks up at the same point in it.
    func play(_ book: Audiobook, from file: AudiobookFile? = nil) {
        if file == nil, isCurrent(book) { return resume() }
        guard let nowPlaying = NowPlayingSpoken(book, startingAt: file) else { return }
        let resumes = nowPlaying.currentFile.path == book.currentFilePath
        start(nowPlaying, at: resumes ? book.playbackPosition : 0, context: book.modelContext)
    }

    /// Stops if one of these episodes is playing, as when its download is removed.
    func stop(_ episodes: [PodcastEpisode]) {
        guard episodes.contains(where: isCurrent) else { return }
        stopSpoken()
    }

    /// Stops the book that's playing if a rescan found it gone.
    func stopAudiobook(missingFrom books: [Audiobook]) {
        guard let currentSpoken, currentSpoken.kind == .audiobook,
              !books.contains(where: { $0.persistentModelID == currentSpoken.id }) else { return }
        stopSpoken()
    }

    func togglePlayPause() {
        isPlaying ? pause() : resume()
    }

    func skipForward() {
        if currentSpoken != nil { return seek(to: elapsed + Self.spokenSkipForward) }
        guard queue.advance(wrapping: isRepeating) else { return }
        loadCurrentTrack()
    }

    func skipBackward() {
        if currentSpoken != nil { return seek(to: max(elapsed - Self.spokenSkipBackward, 0)) }
        if elapsed > Self.restartThreshold || !queue.retreat(wrapping: isRepeating) {
            seek(to: 0)
        } else {
            loadCurrentTrack()
        }
    }

    func seek(to seconds: TimeInterval) {
        elapsed = seconds
        engine.seek(to: seconds)
    }

    func toggleShuffle() {
        isShuffled.toggle()
        queue.setShuffled(isShuffled)
    }

    func toggleRepeat() {
        isRepeating.toggle()
    }

    private func start(_ nowPlaying: NowPlayingSpoken, at position: TimeInterval, context: ModelContext?) {
        leaveSpoken()
        queue = PlaybackQueue()
        currentSpoken = nowPlaying
        spokenContext = context
        savedPosition = position
        loadCurrentFile(at: position)
        resume()
    }

    private func stopSpoken() {
        pause()
        leaveSpoken()
        load(nil)
    }

    private func resume() {
        guard hasCurrentItem else { return }
        engine.play()
        isPlaying = true
        engine.startTicking(every: Self.progressInterval) { [weak self] in self?.updateElapsed() }
    }

    private func pause() {
        engine.pause()
        isPlaying = false
        engine.stopTicking()
        saveSpokenPosition()
    }

    private func updateElapsed() {
        elapsed = engine.currentTime
        if currentSpoken != nil, abs(elapsed - savedPosition) >= Self.positionSaveInterval {
            saveSpokenPosition()
        }
    }

    private func saveSpokenPosition() {
        guard let currentSpoken, let spokenContext else { return }
        SpokenPositionStore.save(currentSpoken, position: elapsed, in: spokenContext)
        savedPosition = elapsed
    }

    private func leaveSpoken() {
        saveSpokenPosition()
        currentSpoken = nil
        spokenContext = nil
    }

    private func loadCurrentFile(at position: TimeInterval) {
        guard let file = currentSpoken?.currentFile else { return }
        load(file.url, at: position)
        if file.duration <= 0 { loadDuration(of: file.url) }
    }

    private func loadDuration(of url: URL) {
        Task { [weak self] in
            guard let duration = await PlaybackEngine.duration(of: url) else { return }
            self?.currentSpoken?.setDuration(duration, of: url)
        }
    }

    private func loadCurrentTrack() {
        load(currentTrack.map { URL(filePath: $0.filePath) })
    }

    private func load(_ url: URL?, at start: TimeInterval = 0) {
        elapsed = start
        engine.load(url, at: start, playing: isPlaying) { [weak self] in self?.trackDidEnd() }
    }

    /// A book goes on to its next file. At the end of the last song, episode or book the player stops, with the
    /// episode or book saved as back at the start.
    private func trackDidEnd() {
        if queue.advance(wrapping: isRepeating) { return loadCurrentTrack() }
        if currentSpoken?.advance() == true { return loadCurrentFile(at: 0) }
        pause()
        if currentSpoken != nil {
            currentSpoken?.rewind()
            loadCurrentFile(at: 0)
        } else {
            seek(to: 0)
        }
        saveSpokenPosition()
    }
}
