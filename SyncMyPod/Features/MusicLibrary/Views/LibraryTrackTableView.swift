import SwiftData
import SwiftUI

struct LibraryTrackTableView: View {
    let tracks: [LibraryTrack]

    @State private var sortOrder = [KeyPathComparator(\LibraryTrack.artist)]

    var body: some View {
        Table(tracks.sorted(using: sortOrder), sortOrder: $sortOrder) {
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
    }
}

#Preview {
    LibraryTrackTableView(tracks: LibraryTrack.previewTracks)
        .modelContainer(.emptyPreview)
}
