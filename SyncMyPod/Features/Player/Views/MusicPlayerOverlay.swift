import SwiftUI

/// Floating playback controls between the current song's title and its progress, with its cover beside them.
struct MusicPlayerOverlay: View {
    /// How far scrolling content must reach past the overlay to show its last rows.
    static let clearance = 130.0

    private static let artworkSize = 64.0
    private static let controlSpacing = 14.0
    private static let lineSpacing = 2.0
    /// Fixed so the overlay keeps its size from song to song; long names truncate.
    private static let infoWidth = 220.0
    private static let inset = 8.0
    private static let trailingInset = 16.0
    /// The cover's corner radius plus the inset, so the corners are concentric.
    private static let cornerRadius = 14.0

    let player: MusicPlayerModel

    var body: some View {
        HStack(spacing: Self.controlSpacing) {
            artwork
            VStack(spacing: Self.lineSpacing) {
                nowPlaying
                controls
                PlaybackProgressBar(player: player)
            }
            .frame(width: Self.infoWidth)
        }
        .padding([.leading, .vertical], Self.inset)
        .padding(.trailing, Self.trailingInset)
        .glassEffect(.regular, in: .rect(cornerRadius: Self.cornerRadius))
    }

    @ViewBuilder
    private var artwork: some View {
        switch player.currentSpoken?.artwork {
        case .podcast(let data):
            PodcastArtworkView(data: data, size: Self.artworkSize)
        case .embedded(let path, let fingerprint):
            AlbumArtworkView(path: path, fingerprint: fingerprint, placeholderSystemImage: "book.closed")
                .frame(width: Self.artworkSize, height: Self.artworkSize)
        case nil:
            AlbumArtworkView(path: player.currentTrack?.filePath, fingerprint: player.currentTrack?.artworkFingerprint)
                .frame(width: Self.artworkSize, height: Self.artworkSize)
        }
    }

    private var title: String? { player.currentSpoken?.currentFile.title ?? player.currentTrack?.title }

    private var subtitle: String? { player.currentSpoken?.collectionTitle ?? player.currentTrack?.artist }

    private var nowPlaying: some View {
        VStack(spacing: 0) {
            Text(title ?? "Not Playing")
                .font(.callout.weight(.semibold))
            Text(subtitle ?? " ")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .truncationMode(.tail)
        .help(nowPlayingText)
    }

    private var controls: some View {
        HStack(spacing: Self.controlSpacing) {
            toggle("Shuffle", systemImage: "shuffle", isOn: player.isShuffled, action: player.toggleShuffle)
                .disabled(isSpoken)
            Button(isSpoken ? "Back 15 Seconds" : "Previous",
                   systemImage: isSpoken ? "gobackward.15" : "backward.fill", action: player.skipBackward)
                .disabled(!player.hasCurrentItem)
            Button(player.isPlaying ? "Pause" : "Play", systemImage: player.isPlaying ? "pause.fill" : "play.fill",
                   action: player.togglePlayPause)
                .font(.title)
                .contentTransition(.symbolEffect(.replace))
                .disabled(!player.hasCurrentItem)
            Button(isSpoken ? "Forward 30 Seconds" : "Next",
                   systemImage: isSpoken ? "goforward.30" : "forward.fill", action: player.skipForward)
                .disabled(!player.canSkipForward)
            toggle("Repeat", systemImage: "repeat", isOn: player.isRepeating, action: player.toggleRepeat)
                .disabled(isSpoken)
        }
        .font(.title3)
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
    }

    private func toggle(_ title: String, systemImage: String, isOn: Bool,
                        action: @escaping () -> Void) -> some View {
        Button(title, systemImage: systemImage, action: action)
            .foregroundStyle(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .accessibilityValue(isOn ? "On" : "Off")
    }

    /// Episodes and books skip by seconds and have no shuffle or repeat.
    private var isSpoken: Bool { player.currentSpoken != nil }

    private var nowPlayingText: String {
        guard let title else { return "Not Playing" }
        return [title, subtitle ?? ""].filter { !$0.isEmpty }.joined(separator: " — ")
    }
}

#if DEBUG
#Preview {
    MusicPlayerOverlay(player: MusicPlayerModel())
        .padding()
        .frame(width: 500, height: 200)
        .background(.blue.gradient)
}
#endif
