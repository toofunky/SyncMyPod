import SwiftData
import SwiftUI

struct LibraryTrackTableView: View {
    let tracks: [LibraryTrack]
    @Binding var selection: Set<LibraryTrack.ID>
    var addToIPod: (([LibraryTrack]) -> Void)?

    @Environment(\.modelContext) private var context
    @Query(sort: \LibraryPlaylist.createdAt) private var playlists: [LibraryPlaylist]
    @State private var sortOrder = [KeyPathComparator(\LibraryTrack.albumArtist)]
    @State private var sortedTracks: [LibraryTrack] = []
    @State private var sortKeys: [LibraryTrackSortKey] = []
    @State private var sortedBy: KeyPathComparator<LibraryTrack>?

    var body: some View {
        Table(sortedTracks, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Track #", value: \.trackNumber) { track in
                Text(track.trackPosition.displayText)
                    .monospacedDigit()
            }
            TableColumn("Disc #", value: \.discNumber) { track in
                Text(track.discPosition.displayText)
                    .monospacedDigit()
            }
            TableColumn("Title", value: \.title)
            TableColumn("Artist", value: \.artist)
            TableColumn("Album Artist", value: \.albumArtist)
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
            TableColumn("Codec", value: \.codecName)
        }
        // A fresh table lays out only visible rows; diffing a full reorder builds a row view for every track.
        .id(sortedBy)
        .contextMenu(forSelectionType: LibraryTrack.ID.self) { ids in
            Button("Add to iPod", systemImage: "ipod") {
                addToIPod?(tracks.filter { ids.contains($0.id) })
            }
            .disabled(addToIPod == nil || ids.isEmpty)
            AddToPlaylistMenu(playlists: playlists) { add(ids, to: $0) }
                .disabled(ids.isEmpty)
        }
        .onChange(of: tracks, initial: true) {
            sortKeys = LibraryTrack.sortKeys(for: tracks)
            resort()
        }
        .onChange(of: sortOrder) { resort() }
    }

    private func resort() {
        sortedBy = sortOrder.first
        guard let primary = sortedBy else { return sortedTracks = tracks }
        sortedTracks = LibraryTrack.sorted(tracks, keys: sortKeys, by: primary)
    }

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
    LibraryTrackTableView(tracks: LibraryTrack.previewTracks, selection: .constant([]), addToIPod: { _ in })
        .modelContainer(.emptyPreview)
}
