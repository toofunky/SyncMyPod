import AppKit
import SwiftData
import SwiftUI

/// The episode table's context menu, acting on every selected episode it applies to.
struct PodcastEpisodeMenu: View {
    let episodes: [PodcastEpisode]
    let download: ([PodcastEpisode]) -> Void

    @Environment(PodcastDownloads.self) private var downloads
    @Environment(MusicPlayerModel.self) private var player: MusicPlayerModel?
    @Environment(\.modelContext) private var context

    var body: some View {
        Button("Play", systemImage: "play") { play(fromBeginning: false) }
            .disabled(downloaded.isEmpty || player == nil)
        Button("Play from Beginning", systemImage: "backward.end") { play(fromBeginning: true) }
            .disabled(downloaded.isEmpty || player == nil)
        Divider()
        Button("Download", systemImage: "arrow.down.circle") { download(downloadable) }
            .disabled(downloadable.isEmpty)
        Button("Cancel Download", systemImage: "xmark.circle") { downloads.cancel(inProgress) }
            .disabled(inProgress.isEmpty)
        Divider()
        Button("Show in Finder", systemImage: "folder") {
            NSWorkspace.shared.activateFileViewerSelecting(downloaded.compactMap(\.downloadedFileURL))
        }
        .disabled(downloaded.isEmpty)
        Button("Remove Download", systemImage: "trash") {
            player?.stop(downloaded)
            downloads.removeDownloads(of: downloaded, context: context)
        }
        .disabled(downloaded.isEmpty)
    }

    private var inProgress: [PodcastEpisode] { episodes.filter { downloads.state(of: $0) != nil } }

    private var downloadable: [PodcastEpisode] {
        episodes.filter { !$0.isDownloaded && downloads.state(of: $0) == nil }
    }

    private var downloaded: [PodcastEpisode] { episodes.filter(\.isDownloaded) }

    private func play(fromBeginning: Bool) {
        guard let episode = downloaded.first, let player else { return }
        player.play(episode)
        if fromBeginning { player.seek(to: 0) }
    }
}

#if DEBUG
#Preview {
    Menu("Episodes") {
        PodcastEpisodeMenu(episodes: PodcastEpisode.previewEpisodes) { _ in }
    }
    .padding()
    .environment(PodcastDownloads())
    .environment(MusicPlayerModel())
    .modelContainer(.emptyPreview)
}
#endif
