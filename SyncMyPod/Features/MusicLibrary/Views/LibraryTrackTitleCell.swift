import SwiftUI

/// A song's title, marked when the song has a lyric file or is a favorite.
struct LibraryTrackTitleCell: View {
    let track: LibraryTrack

    var body: some View {
        HStack {
            Text(track.title)
                .lineLimit(1)
            TrackStatusIcons(track: track)
        }
    }
}

#if DEBUG
#Preview {
    let track = LibraryTrack.preview("Hey Ya!", artist: "OutKast", album: "Speakerboxxx/The Love Below", duration: 235)
    track.hasLyrics = true
    return LibraryTrackTitleCell(track: track)
        .environment(\.favoriteTrackPaths, [track.filePath])
        .padding()
}
#endif
