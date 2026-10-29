import SwiftUI

struct LibrarySummaryView: View {
    let database: ITunesDatabase

    var body: some View {
        HStack {
            Label("\(database.tracks.count) tracks", systemImage: "music.note")
            Label("\(database.userPlaylists.count) playlists", systemImage: "music.note.list")
            Spacer()
            Text("iTunesDB version \(database.version)")
                .foregroundStyle(.secondary)
        }
        .font(.callout)
        .padding()
    }
}

#if DEBUG
#Preview {
    LibrarySummaryView(database: .preview)
}
#endif
