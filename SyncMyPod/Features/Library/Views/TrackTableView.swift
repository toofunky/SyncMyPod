import SwiftUI

struct TrackTableView: View {
    let tracks: [ITunesTrack]
    var searchText = ""

    @State private var sortOrder = [KeyPathComparator(\ITunesTrack.artist)]
    @State private var sortedTracks: [ITunesTrack] = []
    @State private var filteredBy = ""

    var body: some View {
        Table(sortedTracks, sortOrder: $sortOrder) {
            TableColumn("Title", value: \.title)
            TableColumn("Artist", value: \.artist)
            TableColumn("Album Artist", value: \.albumArtist)
            TableColumn("Album", value: \.album)
            TableColumn("Time", value: \.duration) { track in
                Text(Duration.seconds(track.duration), format: .time(pattern: .minuteSecond))
                    .monospacedDigit()
            }
            TableColumn("Plays", value: \.playCount) { track in
                Text(track.playCount, format: .number)
                    .monospacedDigit()
            }
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
