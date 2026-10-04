import SwiftUI

struct AlbumTrackRow: View {
    private static let numberWidth = 20.0

    let track: LibraryTrack
    /// Shown only when the song's artist differs from the album's, as on compilations.
    let albumArtist: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            NowPlayingIndicator(track: track) {
                Text(track.trackNumber > 0 ? String(track.trackNumber) : "")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: Self.numberWidth, alignment: .trailing)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(track.title)
                    TrackStatusIcons(track: track)
                }
                if showsArtist {
                    Text(track.artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            Spacer()
            Text(Duration.seconds(track.duration), format: .time(pattern: .minuteSecond))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private var showsArtist: Bool {
        !track.artist.isEmpty && track.artist != albumArtist
    }
}

#if DEBUG
#Preview {
    List(LibraryTrack.previewTracks) { track in
        AlbumTrackRow(track: track, albumArtist: "OutKast")
    }
    .environment(\.favoriteTrackPaths, [LibraryTrack.previewTracks[0].filePath])
    .frame(width: 300)
}
#endif
