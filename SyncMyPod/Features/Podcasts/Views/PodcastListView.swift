import AppKit
import SwiftData
import SwiftUI

struct PodcastListView: View {
    let podcasts: [Podcast]
    @Binding var selection: UUID?

    @Environment(PodcastsModel.self) private var model
    @Environment(PodcastDownloads.self) private var downloads
    @Environment(\.modelContext) private var context
    @State private var podcastToRemove: Podcast?

    var body: some View {
        List(selection: $selection) {
            ForEach(podcasts) { podcast in
                PodcastRow(podcast: podcast)
                    .tag(podcast.podcastID)
                    .contextMenu { menu(for: podcast) }
            }
        }
        .onAppear(perform: selectFirstIfNeeded)
        .onDeleteCommand { podcastToRemove = podcasts.first { $0.podcastID == selection } }
        .confirmationDialog("Unsubscribe from “\(podcastToRemove?.title ?? "")”?", isPresented: isConfirmingRemoval,
                            presenting: podcastToRemove) { podcast in
            Button("Unsubscribe", role: .destructive) { unsubscribe(from: podcast) }
        } message: { podcast in
            Text(removalMessage(for: podcast))
        }
    }

    @ViewBuilder
    private func menu(for podcast: Podcast) -> some View {
        Button("Refresh", systemImage: "arrow.clockwise") {
            Task { await model.refresh(podcast, in: context) }
        }
        .disabled(model.isRefreshing(podcast))
        Button("Copy Feed Address", systemImage: "doc.on.doc") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(podcast.feedURL, forType: .string)
        }
        Divider()
        Button("Unsubscribe…", systemImage: "trash", role: .destructive) { podcastToRemove = podcast }
    }

    private var isConfirmingRemoval: Binding<Bool> {
        Binding(get: { podcastToRemove != nil }, set: { if !$0 { podcastToRemove = nil } })
    }

    private func selectFirstIfNeeded() {
        guard selection == nil || !podcasts.contains(where: { $0.podcastID == selection }) else { return }
        selection = podcasts.first?.podcastID
    }

    private func removalMessage(for podcast: Podcast) -> String {
        let downloaded = podcast.episodes.count(where: \.isDownloaded)
        let files = downloaded == 1 ? "Its downloaded episode is" : "Its \(downloaded) downloaded episodes are"
        return "Its episode list is removed from SyncMyPod." + (downloaded > 0 ? " \(files) moved to the Trash." : "")
    }

    private func unsubscribe(from podcast: Podcast) {
        if selection == podcast.podcastID { selection = nil }
        downloads.cancel(podcast.episodes)
        downloads.removeDownloads(of: podcast.episodes, context: context)
        model.unsubscribe(from: podcast, in: context)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: UUID?
    PodcastListView(podcasts: [.preview], selection: $selection)
        .environment(PodcastsModel())
        .environment(PodcastDownloads())
        .modelContainer(.preview)
        .frame(width: 260, height: 300)
}
#endif
