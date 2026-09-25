import SwiftUI

struct SyncSelectionTreeView: View {
    let playlists: [SyncPlaylistNode]
    let artists: [SyncArtistNode]
    @Binding var playlistSelection: Set<String>
    @Binding var selection: Set<String>

    var body: some View {
        List {
            if !playlists.isEmpty {
                Section("Playlists") {
                    ForEach(playlists) { playlist in
                        Toggle(isOn: isSelected(playlist.key, in: $playlistSelection)) {
                            playlistLabel(playlist)
                        }
                    }
                }
            }
            Section("Artists") {
                ForEach(artists, content: artistGroup)
            }
        }
        .toggleStyle(.checkbox)
    }

    private func artistGroup(_ artist: SyncArtistNode) -> some View {
        DisclosureGroup {
            ForEach(artist.albums) { album in
                Toggle(isOn: isSelected(album.key, in: $selection)) {
                    albumLabel(album)
                }
            }
        } label: {
            Toggle(sources: artist.albums.map { isSelected($0.key, in: $selection) }, isOn: \.self) {
                Text(artist.name)
            }
        }
    }

    private func playlistLabel(_ playlist: SyncPlaylistNode) -> some View {
        HStack {
            Label(playlist.name, systemImage: "music.note.list")
            Spacer()
            Text("\(playlist.trackCount) songs")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
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

    private func isSelected(_ key: String, in keys: Binding<Set<String>>) -> Binding<Bool> {
        Binding(get: { keys.wrappedValue.contains(key) },
                set: { isOn in
                    if isOn { keys.wrappedValue.insert(key) } else { keys.wrappedValue.remove(key) }
                })
    }
}

#Preview {
    @Previewable @State var playlistSelection: Set<String> = ["road-trip"]
    @Previewable @State var selection: Set<String> = ["Coldplay\u{1F}A Rush of Blood to the Head"]
    SyncSelectionTreeView(playlists: [
        SyncPlaylistNode(key: "road-trip", name: "Road Trip", trackCount: 24),
        SyncPlaylistNode(key: "workout", name: "Workout", trackCount: 40)
    ], artists: [
        SyncArtistNode(name: "Coldplay", albums: [
            SyncAlbumNode(key: "Coldplay\u{1F}A Rush of Blood to the Head", title: "A Rush of Blood to the Head",
                          trackCount: 11, byteCount: 98_000_000),
            SyncAlbumNode(key: "Coldplay\u{1F}Parachutes", title: "Parachutes", trackCount: 10, byteCount: 82_000_000)
        ]),
        SyncArtistNode(name: "OutKast", albums: [
            SyncAlbumNode(key: "OutKast\u{1F}Stankonia", title: "Stankonia", trackCount: 24, byteCount: 150_000_000)
        ])
    ], playlistSelection: $playlistSelection, selection: $selection)
}
