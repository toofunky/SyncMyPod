import SwiftUI

/// A book's cover, taken from the first of its files with embedded artwork.
struct AudiobookArtworkView: View {
    let book: Audiobook
    let size: CGFloat

    var body: some View {
        let file = book.artworkFile
        AlbumArtworkView(path: file?.filePath, fingerprint: file?.artworkFingerprint,
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
