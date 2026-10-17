import SwiftData
import SwiftUI

/// A podcast's show details above its episodes.
struct PodcastDetailView: View {
    let podcast: Podcast

    var body: some View {
        VStack(spacing: 0) {
            PodcastHeaderView(podcast: podcast)
            Divider()
            if podcast.episodes.isEmpty {
                ContentUnavailableView("No Episodes", systemImage: "waveform",
                                       description: Text("This podcast's feed doesn't list any episodes."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PodcastEpisodeTable(episodes: podcast.sortedEpisodes)
            }
        }
    }
}

#if DEBUG
#Preview {
    PodcastDetailView(podcast: .preview)
        .environment(PodcastsModel())
        .modelContainer(.preview)
        .frame(width: 640, height: 400)
}
#endif
