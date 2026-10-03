import SwiftUI

struct SyncSummaryBar: View {
    /// `nil` until the first plan has been worked out.
    let totals: SyncPlanTotals?
    var deviceKind = "iPod"
    let isCalculating: Bool
    let freeBytes: Int64?
    let isSyncing: Bool
    let onSync: () -> Void

    private var fits: Bool { totals?.fits(in: freeBytes) ?? true }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(headline)
                    .font(.headline)
                Text(detail)
                    .foregroundStyle(fits ? Color.secondary : Color.red)
            }
            Spacer()
            if isCalculating || isSyncing {
                ProgressView()
                    .controlSize(.small)
            }
            Button("Sync Now", systemImage: "arrow.triangle.2.circlepath", action: onSync)
                .buttonStyle(.borderedProminent)
                .disabled(totals?.isEmpty ?? true || isCalculating || isSyncing || !fits)
        }
        .padding()
    }

    private var headline: String {
        guard let totals else { return "Calculating…" }
        guard !totals.isEmpty else {
            return totals.selectedCount == 0 ? "Nothing selected" : "The \(deviceKind) is up to date"
        }
        var parts: [String] = []
        if totals.addCount > 0 { parts.append("\(songs(totals.addCount)) to add · \(bytes(totals.addBytes))") }
        if totals.updateCount > 0 {
            parts.append("\(songs(totals.updateCount)) to update · \(bytes(totals.updateBytes))")
        }
        if totals.moveCount > 0 { parts.append("\(songs(totals.moveCount)) to rename") }
        if totals.removeCount > 0 {
            parts.append("\(songs(totals.removeCount)) to remove · \(bytes(totals.removeBytes))")
        }
        if totals.playlistChangeCount > 0 {
            let count = totals.playlistChangeCount
            parts.append("\(count) \(count == 1 ? "playlist" : "playlists") to update")
        }
        if totals.sidecarChangeCount > 0 {
            let count = totals.sidecarChangeCount
            parts.append("\(count) cover and lyric \(count == 1 ? "file" : "files") to update")
        }
        return parts.joined(separator: " · ")
    }

    private var detail: String {
        let free = freeBytes.map { "\(bytes($0)) free" } ?? "Free space unknown"
        guard fits else { return "Not enough space on the \(deviceKind) · \(free)" }
        guard let totals else { return free }
        return "\(totals.alreadyOnDeviceCount) already on the \(deviceKind) · \(free)"
    }

    private func songs(_ count: Int) -> String { "\(count) \(count == 1 ? "song" : "songs")" }
    private func bytes(_ count: Int64) -> String { count.formatted(.byteCount(style: .file)) }
}

#if DEBUG
#Preview("Adding and removing") {
    SyncSummaryBar(totals: SyncPlanTotals(addCount: 1, addBytes: 8_000_000, moveCount: 2, removeCount: 1,
                                          removeBytes: 6_000_000, selectedCount: 3),
                   isCalculating: false, freeBytes: 38_000_000_000, isSyncing: false, onSync: {})
}

#Preview("Up to date") {
    SyncSummaryBar(totals: SyncPlanTotals(selectedCount: 3), deviceKind: "Player", isCalculating: false,
                   freeBytes: 38_000_000_000, isSyncing: false, onSync: {})
}

#Preview("Calculating") {
    SyncSummaryBar(totals: nil, isCalculating: true, freeBytes: 38_000_000_000, isSyncing: false, onSync: {})
}
#endif
