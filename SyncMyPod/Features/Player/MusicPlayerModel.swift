import AVFoundation
import Observation

@Observable
final class MusicPlayerModel {
    /// Skipping back this far into a song restarts it instead of going to the previous one.
    private static let restartThreshold = 3.0

    private(set) var queue = PlaybackQueue()
    private(set) var isPlaying = false
    private(set) var isShuffled = false
    private(set) var isRepeating = false

    @ObservationIgnored private let player = AVPlayer()
    @ObservationIgnored private var endObserver: Task<Void, Never>?

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
        if player.currentTime().seconds > Self.restartThreshold || !queue.retreat(wrapping: isRepeating) {
            player.seek(to: .zero)
        } else {
            loadCurrentTrack()
        }
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
    }

    private func pause() {
        player.pause()
        isPlaying = false
    }

    /// The player keeps its rate across items, so a new song plays only if the last one was playing.
    private func loadCurrentTrack() {
        endObserver?.cancel()
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
            player.seek(to: .zero)
            pause()
        }
    }
}
