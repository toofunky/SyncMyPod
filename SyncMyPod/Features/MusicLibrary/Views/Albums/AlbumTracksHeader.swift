import SwiftUI

struct AlbumTracksHeader: View {
    let album: LibraryAlbum
    let duration: TimeInterval

    var body: some View {
        VStack(alignment: .leading) {
            AlbumArtworkView(path: album.artworkPath, fingerprint: album.artworkFingerprint)
            Text(album.title)
                .font(.title3)
                .fontWeight(.semibold)
            Text(album.artist)
                .foregroundStyle(.secondary)
            Text(details)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var details: String {
        let songs = album.trackCount == 1 ? "1 song" : "\(album.trackCount) songs"
        let minutes = Int((duration / 60).rounded())
        return [album.yearText, songs, "\(minutes) min"].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

#if DEBUG
#Preview {
    AlbumTracksHeader(album: .preview, duration: 3_600)
        .frame(width: 280)
        .padding()
}
#endif
