import SwiftUI

/// A speaker beside the song that's playing; any other song shows `fallback` instead.
struct NowPlayingIndicator<Fallback: View>: View {
    let track: LibraryTrack
    @ViewBuilder var fallback: Fallback

    @Environment(MusicPlayerModel.self) private var player: MusicPlayerModel?

    var body: some View {
        if let player, player.isCurrent(track) {
            Image(systemName: player.isPlaying ? "speaker.wave.2.fill" : "speaker.fill")
                .foregroundStyle(.tint)
                .accessibilityLabel(player.isPlaying ? "Now Playing" : "Paused")
        } else {
            fallback
        }
    }
}

extension NowPlayingIndicator where Fallback == EmptyView {
    init(track: LibraryTrack) {
        self.init(track: track) { EmptyView() }
    }
}

#if DEBUG
#Preview {
    NowPlayingIndicator(track: LibraryTrack.previewTracks[0]) {
        Text("9")
    }
    .padding()
}
#endif
