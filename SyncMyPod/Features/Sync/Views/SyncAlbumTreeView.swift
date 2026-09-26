import SwiftUI

struct SyncAlbumTreeView: View {
    let artists: [SyncArtistNode]
    @Binding var selection: Set<String>

    var body: some View {
        List {
            ForEach(artists, content: artistGroup)
        }
        .toggleStyle(.checkbox)
    }

    private func artistGroup(_ artist: SyncArtistNode) -> some View {
        DisclosureGroup {
            ForEach(artist.albums) { album in
                Toggle(isOn: $selection.contains(album.key)) {
                    SyncRowLabel(title: album.title,
                                 detail: SyncRowLabel.detail(trackCount: album.trackCount, byteCount: album.byteCount))
                }
            }
        } label: {
            Toggle(sources: artist.albums.map { $selection.contains($0.key) }, isOn: \.self) {
                Text(artist.name)
            }
        }
    }
}

#Preview {
    @Previewable @State var selection: Set<String> = ["Coldplay\u{1F}A Rush of Blood to the Head"]
    SyncAlbumTreeView(artists: [
        SyncArtistNode(name: "Coldplay", albums: [
            SyncAlbumNode(key: "Coldplay\u{1F}A Rush of Blood to the Head", title: "A Rush of Blood to the Head",
                          trackCount: 11, byteCount: 98_000_000),
            SyncAlbumNode(key: "Coldplay\u{1F}Parachutes", title: "Parachutes", trackCount: 10, byteCount: 82_000_000)
        ]),
        SyncArtistNode(name: "OutKast", albums: [
            SyncAlbumNode(key: "OutKast\u{1F}Stankonia", title: "Stankonia", trackCount: 24, byteCount: 150_000_000)
        ])
    ], selection: $selection)
}
