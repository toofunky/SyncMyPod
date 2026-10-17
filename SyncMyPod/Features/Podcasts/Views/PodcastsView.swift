import SwiftData
import SwiftUI

/// Subscribed podcasts beside the selected one's episodes.
struct PodcastsView: View {
    @Binding var selection: UUID?

    @Environment(PodcastsModel.self) private var model
    @Environment(\.modelContext) private var context
    @Query(sort: Podcast.titleOrder) private var podcasts: [Podcast]
    @State private var isAdding = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .sheet(isPresented: $isAdding) {
            AddPodcastSheet { selection = $0.podcastID }
        }
    }

    private var header: some View {
        HStack {
            Text("Podcasts")
                .font(.headline)
            Spacer()
            if model.isRefreshingAny {
                ProgressView()
                    .controlSize(.small)
            }
            Group {
                Button("Refresh All", systemImage: "arrow.clockwise") {
                    Task { await model.refreshAll(in: context) }
                }
                .disabled(podcasts.isEmpty || model.isRefreshingAny)
                Button("Add Podcast…", systemImage: "plus") { isAdding = true }
            }
            .buttonStyle(.borderless)
            .labelStyle(.iconOnly)
        }
        .padding()
    }

    @ViewBuilder
    private var content: some View {
        if podcasts.isEmpty {
            // Inside a scroll view it takes its natural height at the top, instead of centering in the space.
            ScrollView {
                ContentUnavailableView {
                    Label("No Podcasts", systemImage: "antenna.radiowaves.left.and.right")
                } description: {
                    Text("Add a podcast by its RSS feed address.")
                } actions: {
                    Button("Add Podcast…") { isAdding = true }
                }
            }
        } else {
            HSplitView {
                PodcastListView(podcasts: podcasts, selection: $selection)
                    .frame(minWidth: 200, idealWidth: 240, maxWidth: 360)
                detail
                    .frame(minWidth: 360, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let podcast = podcasts.first(where: { $0.podcastID == selection }) {
            PodcastDetailView(podcast: podcast)
                .id(podcast.podcastID)
        } else {
            ContentUnavailableView("No Podcast Selected", systemImage: "antenna.radiowaves.left.and.right",
                                   description: Text("Select a podcast to see its episodes."))
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: UUID? = Podcast.preview.podcastID
    PodcastsView(selection: $selection)
        .environment(PodcastsModel())
        .modelContainer(.preview)
}

#Preview("No Podcasts") {
    PodcastsView(selection: .constant(nil))
        .environment(PodcastsModel())
        .modelContainer(.emptyPreview)
}
#endif
