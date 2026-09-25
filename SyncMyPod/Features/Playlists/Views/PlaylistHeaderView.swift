import SwiftUI

struct PlaylistHeaderView: View {
    @Bindable var playlist: LibraryPlaylist
    let entries: [PlaylistEntry]

    private var totalDuration: TimeInterval {
        entries.reduce(0) { $0 + ($1.track?.duration ?? 0) }
    }

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Playlist Name", text: $playlist.name)
                .textFieldStyle(.plain)
                .font(.title2.bold())
            Text(summary)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding()
    }

    private var summary: String {
        let songs = "\(entries.count) \(entries.count == 1 ? "song" : "songs")"
        guard totalDuration > 0 else { return songs }
        let length = Duration.seconds(totalDuration)
            .formatted(.units(allowed: [.hours, .minutes], width: .wide))
        return "\(songs) · \(length)"
    }
}

#Preview {
    let playlist = LibraryPlaylist.preview
    PlaylistHeaderView(playlist: playlist,
                       entries: PlaylistEntry.entries(of: playlist, in: LibraryTrack.previewTracks))
}
