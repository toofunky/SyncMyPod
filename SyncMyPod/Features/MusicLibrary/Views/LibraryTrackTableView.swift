import SwiftData
import SwiftUI

struct LibraryTrackTableView: View {
    let tracks: [LibraryTrack]
    var addToIPod: (([LibraryTrack]) -> Void)?

    @Environment(\.modelContext) private var context
    @Query(sort: \LibraryPlaylist.createdAt) private var playlists: [LibraryPlaylist]
    @State private var sortOrder = [KeyPathComparator(\LibraryTrack.artist)]
    @State private var selection = Set<LibraryTrack.ID>()

    var body: some View {
        Table(sortedTracks, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Title", value: \.title)
            TableColumn("Artist", value: \.artist)
            TableColumn("Album", value: \.album)
            TableColumn("Genre", value: \.genre)
            TableColumn("Time", value: \.duration) { track in
                Text(Duration.seconds(track.duration), format: .time(pattern: .minuteSecond))
                    .monospacedDigit()
            }
            TableColumn("Bitrate", value: \.bitrate) { track in
                Text("\(track.bitrate) kbps")
                    .monospacedDigit()
            }
        }
        .contextMenu(forSelectionType: LibraryTrack.ID.self) { ids in
            Button("Add to iPod", systemImage: "ipod") {
                addToIPod?(tracks.filter { ids.contains($0.id) })
            }
            .disabled(addToIPod == nil || ids.isEmpty)
            AddToPlaylistMenu(playlists: playlists) { add(ids, to: $0) }
                .disabled(ids.isEmpty)
        }
    }

    private var sortedTracks: [LibraryTrack] { tracks.sorted(using: sortOrder) }

    /// Adds in the order shown; `nil` makes a new playlist of them.
    private func add(_ ids: Set<LibraryTrack.ID>, to playlist: LibraryPlaylist?) {
        let selected = sortedTracks.filter { ids.contains($0.id) }
        if let playlist {
            playlist.append(selected)
        } else {
            context.insert(LibraryPlaylist(trackPaths: selected.map(\.filePath)))
        }
    }
}

#Preview {
    LibraryTrackTableView(tracks: LibraryTrack.previewTracks, addToIPod: { _ in })
        .modelContainer(.emptyPreview)
}
