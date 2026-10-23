import SwiftUI

/// A book's cover, taken from the first of its files with embedded artwork, or else its folder's cover image.
struct AudiobookArtworkView: View {
    let book: Audiobook
    let size: CGFloat

    var body: some View {
        let artwork = book.artwork
        AlbumArtworkView(path: artwork?.path, fingerprint: artwork?.fingerprint,
                         placeholderFont: .system(size: size / 2.5), placeholderSystemImage: "book.closed")
            .frame(width: size, height: size)
    }
}

#if DEBUG
#Preview {
    AudiobookArtworkView(book: .preview, size: 96)
        .padding()
}
#endif
