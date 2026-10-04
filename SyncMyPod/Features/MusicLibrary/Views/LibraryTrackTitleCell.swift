import SwiftUI

/// A song's title, marked when the song has a lyric file.
struct LibraryTrackTitleCell: View {
    let track: LibraryTrack

    var body: some View {
        HStack {
            Text(track.title)
                .lineLimit(1)
            if track.hasLyrics {
                Image(systemName: "text.page")
                    .foregroundStyle(.secondary)
                    .help("Has lyrics")
                    .accessibilityLabel("Has lyrics")
            }
        }
    }
}

#if DEBUG
#Preview {
    let track = LibraryTrack.preview("Hey Ya!", artist: "OutKast", album: "Speakerboxxx/The Love Below", duration: 235)
    track.hasLyrics = true
    return LibraryTrackTitleCell(track: track)
        .padding()
}
#endif
