import SwiftUI

struct TrackTableView: View {
    let tracks: [ITunesTrack]

    @State private var sortOrder = [KeyPathComparator(\ITunesTrack.artist)]
    @State private var sortedTracks: [ITunesTrack] = []

    var body: some View {
        Table(sortedTracks, sortOrder: $sortOrder) {
            TableColumn("Title", value: \.title)
            TableColumn("Artist", value: \.artist)
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
        .onChange(of: sortOrder, initial: true) {
            sortedTracks = tracks.sorted(using: sortOrder)
        }
    }
}

#Preview {
    TrackTableView(tracks: ITunesDatabase.preview.tracks)
}
