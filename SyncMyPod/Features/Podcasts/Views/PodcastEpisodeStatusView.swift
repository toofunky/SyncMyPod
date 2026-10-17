import SwiftData
import SwiftUI

/// An episode's download button, progress with a cancel button, or downloaded checkmark.
struct PodcastEpisodeStatusView: View {
    let episode: PodcastEpisode
    let download: ([PodcastEpisode]) -> Void

    @Environment(PodcastDownloads.self) private var downloads

    private static let progressWidth: CGFloat = 60

    var body: some View {
        HStack {
            switch downloads.state(of: episode) {
            case .queued:
                Text("Waiting")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                cancelButton
            case .downloading(let fraction):
                ProgressView(value: fraction)
                    .frame(width: Self.progressWidth)
                cancelButton
            case nil:
                idle
            }
        }
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
    }

    @ViewBuilder
    private var idle: some View {
        if episode.isDownloaded {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.secondary)
                .help("Downloaded")
        } else {
            Button("Download", systemImage: "arrow.down.circle") { download([episode]) }
                .help("Download")
            if let error = downloads.error(for: episode) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                    .help("Couldn't download: \(error)")
            }
        }
    }

    private var cancelButton: some View {
        Button("Cancel Download", systemImage: "xmark.circle.fill") { downloads.cancel([episode]) }
            .foregroundStyle(.secondary)
            .help("Cancel Download")
    }
}

#if DEBUG
#Preview {
    VStack(alignment: .leading) {
        ForEach(PodcastEpisode.previewEpisodes) { episode in
            PodcastEpisodeStatusView(episode: episode) { _ in }
        }
    }
    .padding()
    .environment(PodcastDownloads())
    .modelContainer(.emptyPreview)
}
#endif
