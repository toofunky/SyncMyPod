import SwiftUI

struct ArtistListView: View {
    let artists: [LibraryArtist]
    @Binding var selection: LibraryArtist.ID?

    var body: some View {
        ScrollViewReader { proxy in
            List(artists, selection: $selection) { artist in
                VStack(alignment: .leading) {
                    Text(artist.name)
                    Text(artist.albumCountText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
            }
            .onAppear {
                if let selection { proxy.scrollTo(selection, anchor: .center) }
            }
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: LibraryArtist.ID? = "OutKast"
    ArtistListView(artists: LibraryArtist.artists(from: LibraryTrack.previewTracks), selection: $selection)
        .frame(width: 220, height: 300)
}
#endif
