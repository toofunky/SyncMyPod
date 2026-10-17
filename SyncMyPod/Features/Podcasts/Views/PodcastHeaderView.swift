import SwiftData
import SwiftUI

struct PodcastHeaderView: View {
    let podcast: Podcast

    @Environment(PodcastsModel.self) private var model
    @Environment(\.modelContext) private var context

    private static let artworkSize: CGFloat = 96

    var body: some View {
        HStack(alignment: .top) {
            PodcastArtworkView(data: podcast.artworkData, size: Self.artworkSize)
            VStack(alignment: .leading, spacing: 4) {
                Text(podcast.title)
                    .font(.title2.bold())
                    .lineLimit(2)
                if !podcast.author.isEmpty {
                    Text(podcast.author)
                        .foregroundStyle(.secondary)
                }
                Text(podcast.summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .help(podcast.summary)
                details
            }
            Spacer(minLength: 0)
            Button("Refresh", systemImage: "arrow.clockwise") {
                Task { await model.refresh(podcast, in: context) }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .disabled(model.isRefreshing(podcast))
        }
        .padding()
    }

    private var details: some View {
        HStack(spacing: 4) {
            Text("^[\(podcast.episodes.count) episode](inflect: true)")
            if downloadedCount > 0 {
                Text("·")
                Text("\(downloadedCount) downloaded")
            }
            if let lastRefreshed = podcast.lastRefreshed {
                Text("·")
                Text("Updated \(lastRefreshed, format: .relative(presentation: .named))")
            }
        }
        .font(.caption)
        .foregroundStyle(.tertiary)
    }

    private var downloadedCount: Int { podcast.episodes.count(where: \.isDownloaded) }
}

#if DEBUG
#Preview {
    PodcastHeaderView(podcast: .preview)
        .environment(PodcastsModel())
        .modelContainer(.preview)
        .frame(width: 600)
}
#endif
