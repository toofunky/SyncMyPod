import SwiftData
import SwiftUI

struct LibraryTrackTableView: View {
    let tracks: [LibraryTrack]
    var addToIPod: (([LibraryTrack]) -> Void)?

    @State private var sortOrder = [KeyPathComparator(\LibraryTrack.artist)]
    @State private var selection = Set<LibraryTrack.ID>()

    var body: some View {
        Table(tracks.sorted(using: sortOrder), selection: $selection, sortOrder: $sortOrder) {
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
        }
    }
}

#Preview {
    LibraryTrackTableView(tracks: LibraryTrack.previewTracks, addToIPod: { _ in })
        .modelContainer(.emptyPreview)
}
