import SwiftUI

/// Marks a song that has a lyric file or is a favorite; shown after its title.
struct TrackStatusIcons: View {
    let track: LibraryTrack

    @Environment(\.favoriteTrackPaths) private var favoriteTrackPaths

    var body: some View {
        if track.hasLyrics {
            Image(systemName: "text.page")
                .foregroundStyle(.secondary)
                .help("Has lyrics")
                .accessibilityLabel("Has lyrics")
        }
        if favoriteTrackPaths.contains(track.filePath) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
                .help("Favorite")
                .accessibilityLabel("Favorite")
        }
    }
}

#if DEBUG
#Preview {
    let track = LibraryTrack.previewTracks[0]
    track.hasLyrics = true
    return HStack { TrackStatusIcons(track: track) }
        .environment(\.favoriteTrackPaths, [track.filePath])
        .padding()
}
#endif
