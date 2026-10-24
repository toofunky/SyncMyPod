import SwiftUI

struct LibraryView: View {
    let device: IPodDevice
    /// Changing this reads the iPod again.
    var reloadID = 0
    var onRemove: ([ITunesTrack]) -> Void = { _ in }
    var onDone: () -> Void = {}

    @Environment(\.iTunesDBLoader) private var loader
    @State private var state = LibraryLoadState.loading
    @State private var searchText = ""
    @State private var selection = Set<ITunesTrack.ID>()

    var body: some View {
        VStack(spacing: 0) {
            content
            Divider()
            StorageSelectionBar(selected: selectedTracks(selection), onRemove: { onRemove(selectedTracks(selection)) },
                                onDone: onDone)
        }
        .task(id: "\(device.id)#\(reloadID)") { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView("Reading iPod library…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let database):
            VStack(alignment: .leading, spacing: 0) {
                LibrarySummaryView(database: database)
                TrackTableView(tracks: database.tracks, searchText: searchText, selection: $selection) { ids in
                    onRemove(selectedTracks(ids))
                }
            }
            .searchable(text: $searchText, prompt: "Search iPod")
        case .failed(let message):
            ContentUnavailableView("Couldn't Read Library",
                                   systemImage: "exclamationmark.triangle",
                                   description: Text(message))
        }
    }

    private func selectedTracks(_ ids: Set<ITunesTrack.ID>) -> [ITunesTrack] {
        guard case .loaded(let database) = state else { return [] }
        return database.tracks.filter { ids.contains($0.id) }
    }

    /// Later reloads keep the table up until the new list arrives, so the sheet doesn't flash a spinner.
    /// The selection is cleared because removals can renumber the iPod's track IDs.
    private func load() async {
        do {
            let database = try await loader.load(device.volumeURL)
            selection = []
            state = .loaded(database)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    LibraryView(device: .preview)
        .environment(\.iTunesDBLoader, .preview)
}

#Preview("Failed") {
    LibraryView(device: .preview)
        .environment(\.iTunesDBLoader, .missingDatabase)
}
#endif
