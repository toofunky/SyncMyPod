import SwiftUI

struct AlbumGridCell: View {
    private static let selectionPadding = 6.0
    private static let selectionCornerRadius = 10.0
    private static let selectionOpacity = 0.25

    let album: LibraryAlbum
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading) {
            AlbumArtworkView(path: album.artworkPath, fingerprint: album.artworkFingerprint)
            VStack(alignment: .leading, spacing: 0) {
                Text(album.title)
                    .fontWeight(.medium)
                Text(album.artist)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
        }
        .padding(Self.selectionPadding)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: Self.selectionCornerRadius)
                    .fill(.tint.opacity(Self.selectionOpacity))
            }
        }
        .contentShape(.rect)
    }
}

#if DEBUG
#Preview {
    HStack {
        AlbumGridCell(album: .preview, isSelected: false)
        AlbumGridCell(album: .preview, isSelected: true)
    }
    .frame(width: 400)
    .padding()
}
#endif
