import AppKit
import SwiftData
import SwiftUI

struct PodcastListView: View {
    let podcasts: [Podcast]
    @Binding var selection: UUID?

    @Environment(PodcastsModel.self) private var model
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
        } message: { _ in
            Text("Its episode list is removed from SyncMyPod.")
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

    private func unsubscribe(from podcast: Podcast) {
        if selection == podcast.podcastID { selection = nil }
        model.unsubscribe(from: podcast, in: context)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: UUID?
    PodcastListView(podcasts: [.preview], selection: $selection)
        .environment(PodcastsModel())
        .modelContainer(.preview)
        .frame(width: 260, height: 300)
}
#endif
