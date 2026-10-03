import SwiftUI

/// A track's cover, dimmed behind a centered speaker while it's the song that's playing.
struct PlaylistTrackArtwork: View {
    private static let scrimOpacity = 0.45

    let track: LibraryTrack

    @Environment(MusicPlayerModel.self) private var player: MusicPlayerModel?

    var body: some View {
        AlbumArtworkView(path: track.filePath, fingerprint: track.artworkFingerprint, placeholderFont: .body)
            .overlay {
                if let player, player.isCurrent(track) {
                    speaker(isPlaying: player.isPlaying)
                }
            }
            .clipShape(.rect(cornerRadius: AlbumArtworkView.cornerRadius))
    }

    private func speaker(isPlaying: Bool) -> some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(Self.scrimOpacity))
            Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.fill")
                .foregroundStyle(.white)
        }
        .accessibilityElement()
        .accessibilityLabel(isPlaying ? "Now Playing" : "Paused")
    }
}

#if DEBUG
#Preview {
    PlaylistTrackArtwork(track: LibraryTrack.previewTracks[0])
        .frame(width: 32, height: 32)
        .padding()
}
#endif
