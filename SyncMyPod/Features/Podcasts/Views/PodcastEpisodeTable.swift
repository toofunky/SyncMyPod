import SwiftData
import SwiftUI

/// A podcast's episodes, newest first. Double-clicking a downloaded episode plays it from where it was left.
struct PodcastEpisodeTable: View {
    let episodes: [PodcastEpisode]
    let download: ([PodcastEpisode]) -> Void

    @Environment(MusicPlayerModel.self) private var player: MusicPlayerModel?
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
                Text(Self.formatted(duration: episode.duration, position: episode.playbackPosition))
            }
            .width(min: 60, ideal: 110)
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
        } primaryAction: { ids in
            if let episode = episodes.first(where: { ids.contains($0.id) && $0.isDownloaded }) {
                player?.play(episode)
            }
        }
    }

    /// A partly heard episode shows the time it has left.
    private static func formatted(duration: TimeInterval?, position: TimeInterval) -> String {
        guard let duration else { return "" }
        guard position > 0, position < duration else { return formatted(duration) }
        return "\(formatted(duration - position)) left"
    }

    private static func formatted(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}

#if DEBUG
#Preview {
    PodcastEpisodeTable(episodes: Podcast.preview.sortedEpisodes) { _ in }
        .environment(PodcastDownloads())
        .environment(MusicPlayerModel())
        .modelContainer(.preview)
        .frame(width: 720, height: 240)
}
#endif
