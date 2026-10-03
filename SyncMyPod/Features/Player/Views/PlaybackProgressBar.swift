import SwiftUI

/// How far through the song the player is; dragging or clicking it moves playback there.
struct PlaybackProgressBar: View {
    private static let timeWidth = 34.0

    let player: MusicPlayerModel

    /// Where the thumb is while it's being dragged, so playback updates don't pull it back.
    @State private var scrubPosition: TimeInterval?

    var body: some View {
        HStack {
            timeText(position)
                .frame(width: Self.timeWidth, alignment: .trailing)
            PlaybackScrubber(fraction: duration > 0 ? position / duration : 0,
                             onScrub: { scrubPosition = $0 * duration },
                             onCommit: commit)
                .disabled(player.currentTrack == nil)
            timeText(duration - position, prefix: "-")
                .frame(width: Self.timeWidth, alignment: .leading)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .monospacedDigit()
    }

    private var duration: TimeInterval { player.currentTrack?.duration ?? 0 }

    private var position: TimeInterval { min(scrubPosition ?? player.elapsed, duration) }

    private func commit(_ fraction: Double) {
        player.seek(to: fraction * duration)
        scrubPosition = nil
    }

    private func timeText(_ seconds: TimeInterval, prefix: String = "") -> some View {
        Text(prefix + Duration.seconds(max(seconds, 0)).formatted(.time(pattern: .minuteSecond)))
    }
}

#if DEBUG
#Preview {
    PlaybackProgressBar(player: MusicPlayerModel())
        .frame(width: 220)
        .padding()
}
#endif
