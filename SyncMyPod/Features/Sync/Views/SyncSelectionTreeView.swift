import SwiftUI

struct SyncSelectionTreeView: View {
    let artists: [SyncArtistNode]
    @Binding var selection: Set<String>

    var body: some View {
        List(artists) { artist in
            DisclosureGroup {
                ForEach(artist.albums) { album in
                    Toggle(isOn: isSelected(album.key)) {
                        albumLabel(album)
                    }
                }
            } label: {
                Toggle(sources: artist.albums.map { isSelected($0.key) }, isOn: \.self) {
                    Text(artist.name)
                }
            }
        }
        .toggleStyle(.checkbox)
    }

    private func albumLabel(_ album: SyncAlbumNode) -> some View {
        HStack {
            Text(album.title)
            Spacer()
            Text("\(album.trackCount) songs · \(album.byteCount.formatted(.byteCount(style: .file)))")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func isSelected(_ key: String) -> Binding<Bool> {
        Binding(get: { selection.contains(key) },
                set: { isOn in
                    if isOn { selection.insert(key) } else { selection.remove(key) }
                })
    }
}

#Preview {
    @Previewable @State var selection: Set<String> = ["Coldplay\u{1F}A Rush of Blood to the Head"]
    SyncSelectionTreeView(artists: [
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
