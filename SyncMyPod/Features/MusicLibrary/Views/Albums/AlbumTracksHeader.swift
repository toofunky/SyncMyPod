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
            Text(album.summary(duration: duration))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#if DEBUG
#Preview {
    AlbumTracksHeader(album: .preview, duration: 3_600)
        .frame(width: 280)
        .padding()
}
#endif
