import SwiftData
import SwiftUI

/// A podcast's episodes, newest first.
struct PodcastEpisodeTable: View {
    let episodes: [PodcastEpisode]
    let download: ([PodcastEpisode]) -> Void

    @State private var selection = Set<PodcastEpisode.ID>()

    var body: some View {
        Table(episodes, selection: $selection) {
            TableColumn("Title") { episode in
                Text(episode.title)
                    .help(episode.summary)
            }
            .width(min: 160, ideal: 320)
            TableColumn("Released") { episode in
                Text(episode.publishedAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
            }
            .width(min: 90, ideal: 110)
            TableColumn("Duration") { episode in
                Text(Self.formatted(duration: episode.duration))
            }
            .width(min: 60, ideal: 80)
            TableColumn("Size") { episode in
                Text(episode.byteCount?.formatted(.byteCount(style: .file)) ?? "")
            }
            .width(min: 60, ideal: 70)
            TableColumn("Status") { episode in
                PodcastEpisodeStatusView(episode: episode, download: download)
            }
            .width(min: 90, ideal: 100)
        }
        .contextMenu(forSelectionType: PodcastEpisode.ID.self) { ids in
            PodcastEpisodeMenu(episodes: episodes.filter { ids.contains($0.id) }, download: download)
        }
    }

    private static func formatted(duration: TimeInterval?) -> String {
        guard let duration else { return "" }
        return Duration.seconds(duration).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}

#if DEBUG
#Preview {
    PodcastEpisodeTable(episodes: Podcast.preview.sortedEpisodes) { _ in }
        .environment(PodcastDownloads())
        .modelContainer(.preview)
        .frame(width: 720, height: 240)
}
#endif
