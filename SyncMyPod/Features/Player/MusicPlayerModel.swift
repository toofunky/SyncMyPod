import AVFoundation
import Observation

@Observable
final class MusicPlayerModel {
    /// Skipping back this far into a song restarts it instead of going to the previous one.
    private static let restartThreshold = 3.0
    private static let progressInterval = Duration.milliseconds(250)

    private(set) var queue = PlaybackQueue()
    private(set) var isPlaying = false
    private(set) var isShuffled = false
    private(set) var isRepeating = false
    /// Seconds into the current song, refreshed while it plays.
    private(set) var elapsed: TimeInterval = 0

    @ObservationIgnored private let player = AVPlayer()
    @ObservationIgnored private var endObserver: Task<Void, Never>?
    @ObservationIgnored private var progressUpdates: Task<Void, Never>?

    var currentTrack: LibraryTrack? { queue.current }
    var canSkipForward: Bool { queue.hasNext || (isRepeating && currentTrack != nil) }

    func isCurrent(_ track: LibraryTrack) -> Bool {
        currentTrack?.filePath == track.filePath
    }

    func play(_ tracks: [LibraryTrack], startingAt index: Int) {
        guard tracks.indices.contains(index) else { return }
        queue = PlaybackQueue(tracks: tracks, startingAt: index, shuffled: isShuffled)
        loadCurrentTrack()
        resume()
    }

    func togglePlayPause() {
        isPlaying ? pause() : resume()
    }

    func skipForward() {
        guard queue.advance(wrapping: isRepeating) else { return }
        loadCurrentTrack()
    }

    func skipBackward() {
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
        guard currentTrack != nil else { return }
        player.play()
        isPlaying = true
        trackProgress()
    }

    private func pause() {
        player.pause()
        isPlaying = false
        progressUpdates?.cancel()
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
    }

    /// The player keeps its rate across items, so a new song plays only if the last one was playing.
    private func loadCurrentTrack() {
        endObserver?.cancel()
        elapsed = 0
        guard let track = currentTrack else { return player.replaceCurrentItem(with: nil) }
        let item = AVPlayerItem(url: URL(filePath: track.filePath))
        player.replaceCurrentItem(with: item)
        endObserver = Task { [weak self] in
            let ends = NotificationCenter.default.notifications(named: AVPlayerItem.didPlayToEndTimeNotification,
                                                                object: item)
            for await _ in ends {
                self?.trackDidEnd()
            }
        }
    }

    private func trackDidEnd() {
        if queue.advance(wrapping: isRepeating) {
            loadCurrentTrack()
        } else {
            seek(to: 0)
            pause()
        }
    }
}
