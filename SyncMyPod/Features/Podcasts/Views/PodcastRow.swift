import SwiftData
import SwiftUI

struct PodcastRow: View {
    let podcast: Podcast

    @Environment(PodcastsModel.self) private var model

    private static let artworkSize: CGFloat = 40

    var body: some View {
        HStack {
            PodcastArtworkView(data: podcast.artworkData, size: Self.artworkSize)
            VStack(alignment: .leading) {
                Text(podcast.title)
                    .lineLimit(1)
                Text("^[\(podcast.episodes.count) episode](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            status
        }
    }

    @ViewBuilder
    private var status: some View {
        if model.isRefreshing(podcast) {
            ProgressView()
                .controlSize(.small)
        } else if let error = model.refreshErrors[podcast.feedURL] {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
                .help("Couldn't refresh: \(error)")
        }
    }
}

#if DEBUG
#Preview {
    List {
        PodcastRow(podcast: .preview)
    }
    .environment(PodcastsModel())
    .modelContainer(.preview)
}
#endif
