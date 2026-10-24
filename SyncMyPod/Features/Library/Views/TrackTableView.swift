import SwiftUI

struct TrackTableView: View {
    let tracks: [ITunesTrack]
    var searchText = ""
    @Binding var selection: Set<ITunesTrack.ID>
    var onRemove: (Set<ITunesTrack.ID>) -> Void = { _ in }

    @State private var sortOrder = [KeyPathComparator(\ITunesTrack.sortingArtist, comparator: .localizedStandard)]
    @State private var sortedTracks: [ITunesTrack] = []
    @State private var filteredBy = ""
    @AppStorage("iPodTableColumns") private var columnCustomization = TableColumnCustomization<ITunesTrack>()

    var body: some View {
        Table(sortedTracks, selection: $selection, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
            TableColumn("Title", value: \.sortingTitle) { Text($0.title) }
                .customizationID("title")
                .disabledCustomizationBehavior(.visibility)
            TableColumn("Artist", value: \.sortingArtist) { Text($0.artist) }
                .customizationID("artist")
            TableColumn("Album Artist", value: \.sortingAlbumArtist) { Text($0.albumArtist) }
                .customizationID("albumArtist")
            TableColumn("Album", value: \.sortingAlbum) { Text($0.album) }
                .customizationID("album")
            TableColumn("Composer", value: \.sortingComposer) { Text($0.composer) }
                .customizationID("composer")
                .defaultVisibility(.hidden)
            TableColumn("Year", value: \.year) { track in
                Text(track.year > 0 ? String(track.year) : "")
                    .monospacedDigit()
            }
            .customizationID("year")
            TableColumn("Time", value: \.duration) { track in
                Text(Duration.seconds(track.duration), format: .time(pattern: .minuteSecond))
                    .monospacedDigit()
            }
            .customizationID("duration")
            TableColumn("Size", value: \.fileSize) { track in
                Text(Int64(track.fileSize), format: .byteCount(style: .file))
                    .monospacedDigit()
            }
            .customizationID("fileSize")
            TableColumn("Plays", value: \.playCount) { track in
                Text(track.playCount, format: .number)
                    .monospacedDigit()
            }
            .customizationID("playCount")
        }
        .contextMenu(forSelectionType: ITunesTrack.ID.self) { ids in
            Button("Remove from iPod…", systemImage: "trash", role: .destructive) { onRemove(ids) }
                .disabled(ids.isEmpty)
        }
        .onDeleteCommand { onRemove(selection) }
        // A fresh table lays out only visible rows; diffing inserted search results builds a row view for each.
        .id(filteredBy)
        .onChange(of: sortOrder, initial: true) { updateRows() }
        .onChange(of: searchText) { updateRows() }
        .onChange(of: tracks) { updateRows() }
    }

    /// Rows hidden by a search are deselected so removing never touches songs that aren't shown.
    private func updateRows() {
        filteredBy = searchText
        let query = TrackSearchQuery(searchText)
        sortedTracks = tracks.filter { $0.matches(query) }.sorted(using: sortOrder)
        selection.formIntersection(sortedTracks.map(\.id))
    }
}

#if DEBUG
#Preview {
    TrackTableView(tracks: ITunesDatabase.preview.tracks, selection: .constant([2]))
}
#endif
