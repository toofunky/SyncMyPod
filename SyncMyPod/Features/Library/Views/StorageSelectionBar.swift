import SwiftUI

struct StorageSelectionBar: View {
    let selected: [ITunesTrack]
    let onRemove: () -> Void
    let onDone: () -> Void

    var body: some View {
        HStack {
            Text(summary)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Remove from iPod…", systemImage: "trash", role: .destructive, action: onRemove)
                .disabled(selected.isEmpty)
            Button("Done", action: onDone)
                .keyboardShortcut(.defaultAction)
        }
        .padding()
    }

    private var summary: String {
        guard !selected.isEmpty else { return "Select songs to remove them from the iPod." }
        let bytes = selected.reduce(Int64(0)) { $0 + Int64($1.fileSize) }
        return "\(selected.count) selected · \(bytes.formatted(.byteCount(style: .file)))"
    }
}

#if DEBUG
#Preview("Selected") {
    StorageSelectionBar(selected: ITunesDatabase.preview.tracks, onRemove: {}, onDone: {})
}

#Preview("Nothing selected") {
    StorageSelectionBar(selected: [], onRemove: {}, onDone: {})
}
#endif
