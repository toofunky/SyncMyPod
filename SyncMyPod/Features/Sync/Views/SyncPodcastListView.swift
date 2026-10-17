import SwiftUI

/// Podcasts with downloaded episodes; choosing one syncs all of them.
struct SyncPodcastListView: View {
    let podcasts: [SyncPodcastSnapshot]
    @Binding var selection: Set<String>

    var body: some View {
        if podcasts.isEmpty {
            ContentUnavailableView("No Downloaded Episodes", systemImage: "antenna.radiowaves.left.and.right",
                                   description: Text("Download episodes in Podcasts to sync them."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(podcasts, id: \.key) { podcast in
                Toggle(isOn: $selection.contains(podcast.key)) {
                    SyncRowLabel(title: podcast.name, systemImage: "antenna.radiowaves.left.and.right",
                                 detail: Self.detail(for: podcast))
                }
            }
            .toggleStyle(.checkbox)
        }
    }

    private static func detail(for podcast: SyncPodcastSnapshot) -> String {
        let count = podcast.episodes.count
        return "\(count) \(count == 1 ? "episode" : "episodes") · \(podcast.byteCount.formatted(.byteCount(style: .file)))"
    }
}

#Preview {
    @Previewable @State var selection: Set<String> = []
    let episode = IPodSyncRequest(sourceURL: URL(filePath: "/Podcasts/Show/2026-10-15 Episode.mp3"),
                                  draft: ITunesTrackDraft(title: "Episode", album: "I've Had It", fileSize: 53_000_000),
                                  isPodcast: true)
    SyncPodcastListView(podcasts: [
        SyncPodcastSnapshot(key: "show", playlist: IPodPlaylistRequest(id: 1, name: "I've Had It", createdAt: .now,
                                                                       tracks: [episode]))
    ], selection: $selection)
}
