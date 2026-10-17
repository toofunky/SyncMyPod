import AppKit
import SwiftUI

/// A podcast's show artwork, or a placeholder until its feed's image has been fetched.
struct PodcastArtworkView: View {
    let data: Data?
    let size: CGFloat

    var body: some View {
        artwork
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: size / 8))
    }

    @ViewBuilder
    private var artwork: some View {
        if let data, let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: size / 2.5))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.quaternary)
        }
    }
}

#if DEBUG
#Preview {
    PodcastArtworkView(data: nil, size: 96)
        .padding()
}
#endif
