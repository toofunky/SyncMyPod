import SwiftUI

struct TrackTableView: View {
    let tracks: [ITunesTrack]
    var searchText = ""

    @State private var sortOrder = [KeyPathComparator(\ITunesTrack.sortingArtist, comparator: .localizedStandard)]
    @State private var sortedTracks: [ITunesTrack] = []
    @State private var filteredBy = ""
    @AppStorage("iPodTableColumns") private var columnCustomization = TableColumnCustomization<ITunesTrack>()

    var body: some View {
        Table(sortedTracks, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
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
            TableColumn("Time", value: \.duration) { track in
                Text(Duration.seconds(track.duration), format: .time(pattern: .minuteSecond))
                    .monospacedDigit()
            }
            .customizationID("duration")
            TableColumn("Plays", value: \.playCount) { track in
                Text(track.playCount, format: .number)
                    .monospacedDigit()
            }
            .customizationID("playCount")
        }
        // A fresh table lays out only visible rows; diffing inserted search results builds a row view for each.
        .id(filteredBy)
        .onChange(of: sortOrder, initial: true) { updateRows() }
        .onChange(of: searchText) { updateRows() }
    }

    private func updateRows() {
        filteredBy = searchText
        let query = TrackSearchQuery(searchText)
        sortedTracks = tracks.filter { $0.matches(query) }.sorted(using: sortOrder)
    }
}

#if DEBUG
#Preview {
    TrackTableView(tracks: ITunesDatabase.preview.tracks)
}
#endif
