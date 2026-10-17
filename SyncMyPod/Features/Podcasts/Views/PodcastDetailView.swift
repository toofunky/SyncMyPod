import SwiftData
import SwiftUI

/// A podcast's show details above its episodes.
struct PodcastDetailView: View {
    let podcast: Podcast

    @Environment(PodcastDownloads.self) private var downloads
    @Environment(PodcastFolder.self) private var folder
    @Environment(\.modelContext) private var context
    @State private var episodesAwaitingFolder: [PodcastEpisode] = []
    @State private var isChoosingFolder = false

    var body: some View {
        VStack(spacing: 0) {
            PodcastHeaderView(podcast: podcast)
            Divider()
            if podcast.episodes.isEmpty {
                ContentUnavailableView("No Episodes", systemImage: "waveform",
                                       description: Text("This podcast's feed doesn't list any episodes."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PodcastEpisodeTable(episodes: podcast.sortedEpisodes, download: download)
            }
        }
        .podcastFolderChooser(isPresented: $isChoosingFolder) { _ in
            download(episodesAwaitingFolder)
            episodesAwaitingFolder = []
        }
        .task { downloads.forgetMissingFiles(of: podcast, context: context) }
    }

    /// Asks for the download folder first if one hasn't been chosen yet.
    private func download(_ episodes: [PodcastEpisode]) {
        guard let url = folder.url else {
            episodesAwaitingFolder = episodes
            isChoosingFolder = true
            return
        }
        downloads.download(episodes, into: url, context: context)
    }
}

#if DEBUG
#Preview {
    PodcastDetailView(podcast: .preview)
        .environment(PodcastsModel())
        .environment(PodcastDownloads())
        .environment(PodcastFolder.preview)
        .modelContainer(.preview)
        .frame(width: 720, height: 400)
}
#endif
