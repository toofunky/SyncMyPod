import SwiftUI

struct SyncGenreListView: View {
    let genres: [SyncGenreNode]
    @Binding var selection: Set<String>

    var body: some View {
        List(genres) { genre in
            Toggle(isOn: $selection.contains(genre.name)) {
                SyncRowLabel(title: genre.name, systemImage: "guitars",
                             detail: SyncRowLabel.detail(trackCount: genre.trackCount, byteCount: genre.byteCount))
            }
        }
        .toggleStyle(.checkbox)
    }
}

#Preview {
    @Previewable @State var selection: Set<String> = ["Rock"]
    SyncGenreListView(genres: [
        SyncGenreNode(name: "Hip-Hop", trackCount: 24, byteCount: 150_000_000),
        SyncGenreNode(name: "Rock", trackCount: 21, byteCount: 180_000_000),
        SyncGenreNode(name: "Unknown Genre", trackCount: 3, byteCount: 20_000_000)
    ], selection: $selection)
}
