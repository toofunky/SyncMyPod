import AVFoundation
import Foundation

/// The `AVPlayer` the music player drives: one file at a time, reporting when it plays to its end.
final class PlaybackEngine {
    private static let timescale: CMTimeScale = 600

    private let player = AVPlayer()
    private var endObserver: Task<Void, Never>?
    private var ticks: Task<Void, Never>?

    /// Seconds into the loaded file.
    var currentTime: TimeInterval {
        let seconds = player.currentTime().seconds
        return seconds.isFinite ? seconds : 0
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func seek(to seconds: TimeInterval) {
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: Self.timescale))
    }

    /// Calls `tick` now and every `interval` until `stopTicking()`, to follow the time while playing.
    func startTicking(every interval: Duration, _ tick: @escaping () -> Void) {
        ticks?.cancel()
        ticks = Task {
            while !Task.isCancelled {
                tick()
                try? await Task.sleep(for: interval)
            }
        }
    }

    func stopTicking() {
        ticks?.cancel()
    }

    /// Loads `url` at `start`, or unloads with `nil`. The player pauses itself when an item ends, so it's
    /// restarted when `playing`. `onEnd` runs each time the file plays to its end.
    func load(_ url: URL?, at start: TimeInterval, playing: Bool, onEnd: @escaping () -> Void) {
        endObserver?.cancel()
        guard let url else { return player.replaceCurrentItem(with: nil) }
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        if start > 0 { seek(to: start) }
        if playing { player.play() }
        endObserver = Task {
            let ends = NotificationCenter.default.notifications(named: AVPlayerItem.didPlayToEndTimeNotification,
                                                                object: item)
            for await _ in ends { onEnd() }
        }
    }

    /// Read from the file, for episodes whose feed left their duration out.
    static func duration(of url: URL) async -> TimeInterval? {
        guard let duration = try? await AVURLAsset(url: url).load(.duration), duration.seconds.isFinite else {
            return nil
        }
        return duration.seconds
    }
}
