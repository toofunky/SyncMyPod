import SwiftUI

struct PlaylistTrackRow: View {
    private static let artworkSize = 32.0

    let entry: PlaylistEntry

    var body: some View {
        if let track = entry.track {
            HStack {
                PlaylistTrackArtwork(track: track)
                    .frame(width: Self.artworkSize, height: Self.artworkSize)
                VStack(alignment: .leading) {
                    HStack {
                        Text(track.title)
                        TrackStatusIcons(track: track)
                    }
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
    .environment(\.favoriteTrackPaths, [LibraryTrack.previewTracks[0].filePath])
}
#endif
