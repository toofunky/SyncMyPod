import SwiftUI

struct LibraryView: View {
    let device: IPodDevice

    @Environment(\.iTunesDBLoader) private var loader
    @State private var state = LibraryLoadState.loading

    var body: some View {
        content
            .task(id: device.id) { await load() }
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
                TrackTableView(tracks: database.tracks)
            }
        case .failed(let message):
            ContentUnavailableView("Couldn't Read Library",
                                   systemImage: "exclamationmark.triangle",
                                   description: Text(message))
        }
    }

    private func load() async {
        state = .loading
        do {
            state = .loaded(try await loader.load(device.volumeURL))
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
