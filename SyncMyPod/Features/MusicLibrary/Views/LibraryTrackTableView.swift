import SwiftData
import SwiftUI

struct LibraryTrackTableView: View {
    let tracks: [LibraryTrack]
    @Binding var selection: Set<LibraryTrack.ID>
    var searchText = ""
    var addToIPod: (([LibraryTrack]) -> Void)?

    @Environment(\.modelContext) private var context
    @Query(sort: \LibraryPlaylist.createdAt) private var playlists: [LibraryPlaylist]
    @State private var sortOrder = [KeyPathComparator(\LibraryTrack.albumArtist)]
    @State private var sortedTracks: [LibraryTrack] = []
    @State private var sortKeys: [LibraryTrackSortKey] = []
    @State private var sortedBy: KeyPathComparator<LibraryTrack>?
    @State private var filteredBy = ""
    @AppStorage("libraryTableColumns") private var columnCustomization = TableColumnCustomization<LibraryTrack>()

    var body: some View {
        Table(sortedTracks, selection: $selection, sortOrder: $sortOrder,
              columnCustomization: $columnCustomization) {
            positionColumns
            tagColumns
            audioColumns
        }
        // A fresh table lays out only visible rows; diffing a reorder or inserted search results
        // builds a row view for every changed track.
        .id(sortedBy)
        .id(filteredBy)
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
            updateRows()
        }
        .onChange(of: sortOrder) { updateRows() }
        .onChange(of: searchText) { updateRows() }
    }

    @TableColumnBuilder<LibraryTrack, KeyPathComparator<LibraryTrack>>
    private var positionColumns: some TableColumnContent<LibraryTrack, KeyPathComparator<LibraryTrack>> {
        TableColumn("Track #", value: \.trackNumber) { track in
            Text(track.trackPosition.displayText)
                .monospacedDigit()
        }
        .customizationID("trackNumber")
        TableColumn("Disc #", value: \.discNumber) { track in
            Text(track.discPosition.displayText)
                .monospacedDigit()
        }
        .customizationID("discNumber")
    }

    @TableColumnBuilder<LibraryTrack, KeyPathComparator<LibraryTrack>>
    private var tagColumns: some TableColumnContent<LibraryTrack, KeyPathComparator<LibraryTrack>> {
        TableColumn("Title", value: \.title)
            .customizationID("title")
            .disabledCustomizationBehavior(.visibility)
        TableColumn("Artist", value: \.artist)
            .customizationID("artist")
        TableColumn("Album Artist", value: \.albumArtist)
            .customizationID("albumArtist")
        TableColumn("Album", value: \.album)
            .customizationID("album")
        TableColumn("Composer", value: \.composer)
            .customizationID("composer")
            .defaultVisibility(.hidden)
        TableColumn("Genre", value: \.genre)
            .customizationID("genre")
    }

    @TableColumnBuilder<LibraryTrack, KeyPathComparator<LibraryTrack>>
    private var audioColumns: some TableColumnContent<LibraryTrack, KeyPathComparator<LibraryTrack>> {
        TableColumn("Time", value: \.duration) { track in
            Text(Duration.seconds(track.duration), format: .time(pattern: .minuteSecond))
                .monospacedDigit()
        }
        .customizationID("duration")
        TableColumn("Bitrate", value: \.bitrate) { track in
            Text("\(track.bitrate) kbps")
                .monospacedDigit()
        }
        .customizationID("bitrate")
        TableColumn("Codec", value: \.codecName)
            .customizationID("codec")
    }

    /// Also drops hidden tracks from the selection so the tag editor never edits rows the search hides.
    private func updateRows() {
        sortedBy = sortOrder.first
        filteredBy = searchText
        let query = TrackSearchQuery(searchText)
        let keys = sortKeys.filter { $0.matches(query) }
        if let primary = sortedBy {
            sortedTracks = LibraryTrack.sorted(tracks, keys: keys, by: primary)
        } else {
            sortedTracks = keys.map { tracks[$0.index] }
        }
        selection.formIntersection(sortedTracks.map(\.id))
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

#if DEBUG
#Preview {
    LibraryTrackTableView(tracks: LibraryTrack.previewTracks, selection: .constant([]), addToIPod: { _ in })
        .modelContainer(.emptyPreview)
}
#endif
