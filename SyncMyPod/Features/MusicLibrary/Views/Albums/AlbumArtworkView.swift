import SwiftUI

struct AlbumArtworkView: View {
    static let cornerRadius = 6.0

    let path: String?
    let fingerprint: String?
    var placeholderFont: Font = .largeTitle

    @Environment(\.albumArtworkLoader) private var loader
    @State private var image: CGImage?

    var body: some View {
        RoundedRectangle(cornerRadius: Self.cornerRadius)
            .fill(.quaternary)
            .aspectRatio(1, contentMode: .fit)
            .overlay { content }
            .clipShape(.rect(cornerRadius: Self.cornerRadius))
            .task(id: fingerprint) { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if let image {
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "music.note")
                .font(placeholderFont)
                .foregroundStyle(.secondary)
        }
    }

    private func load() async {
        guard let path, let fingerprint else { return image = nil }
        image = loader.cachedArtwork(for: fingerprint)
        if image == nil {
            image = await loader.artwork(path: path, fingerprint: fingerprint)
        }
    }
}

#Preview {
    AlbumArtworkView(path: nil, fingerprint: nil)
        .frame(width: 200)
        .padding()
}
