import SwiftUI

struct PlaylistTrackRow: View {
    private static let indicatorWidth = 20.0

    let entry: PlaylistEntry

    var body: some View {
        if let track = entry.track {
            HStack {
                NowPlayingIndicator(track: track) {
                    Image(systemName: "speaker.wave.2.fill")
                        .hidden()
                }
                .frame(width: Self.indicatorWidth)
                VStack(alignment: .leading) {
                    Text(track.title)
                    Text([track.artist, track.album].filter { !$0.isEmpty }.joined(separator: " — "))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(Duration.seconds(track.duration), format: .time(pattern: .minuteSecond))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        } else {
            Label {
                Text(URL(filePath: entry.path).lastPathComponent)
                Text("Not in your music library")
            } icon: {
                Image(systemName: "exclamationmark.triangle")
            }
            .foregroundStyle(.secondary)
        }
    }
}

#if DEBUG
#Preview {
    List {
        PlaylistTrackRow(entry: PlaylistEntry(id: 0, path: LibraryTrack.previewTracks[0].filePath,
                                              track: LibraryTrack.previewTracks[0]))
        PlaylistTrackRow(entry: PlaylistEntry(id: 1, path: "/Music/Gone/Missing.m4a", track: nil))
    }
}
#endif
