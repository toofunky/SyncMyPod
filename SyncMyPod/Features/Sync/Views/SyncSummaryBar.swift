import SwiftUI

struct SyncSummaryBar: View {
    /// `nil` until the first plan has been worked out.
    let plan: SyncPlan?
    let isCalculating: Bool
    let freeBytes: Int64?
    let isSyncing: Bool
    let onSync: () -> Void

    private var fits: Bool {
        guard let plan, let freeBytes else { return true }
        return plan.byteCount + plan.updatedByteCount < freeBytes + plan.removedByteCount
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(headline)
                    .font(.headline)
                Text(detail)
                    .foregroundStyle(fits ? Color.secondary : Color.red)
            }
            Spacer()
            if isCalculating {
                ProgressView()
                    .controlSize(.small)
            }
            Button("Sync Now", systemImage: "arrow.triangle.2.circlepath", action: onSync)
                .buttonStyle(.borderedProminent)
                .disabled(plan?.isEmpty ?? true || isCalculating || isSyncing || !fits)
        }
        .padding()
    }

    private var headline: String {
        guard let plan else { return "Calculating…" }
        guard !plan.isEmpty else {
            return plan.selectedCount == 0 ? "Nothing selected" : "The iPod is up to date"
        }
        var parts: [String] = []
        if !plan.requests.isEmpty {
            parts.append("\(songs(plan.requests.count)) to add · \(bytes(plan.byteCount))")
        }
        if !plan.updates.isEmpty {
            parts.append("\(songs(plan.updates.count)) to update · \(bytes(plan.updatedByteCount))")
        }
        if !plan.removals.isEmpty {
            parts.append("\(songs(plan.removals.count)) to remove · \(bytes(plan.removedByteCount))")
        }
        if plan.playlistChangeCount > 0 {
            let count = plan.playlistChangeCount
            parts.append("\(count) \(count == 1 ? "playlist" : "playlists") to update")
        }
        return parts.joined(separator: " · ")
    }

    private var detail: String {
        let free = freeBytes.map { "\(bytes($0)) free" } ?? "Free space unknown"
        guard fits else { return "Not enough space on the iPod · \(free)" }
        guard let plan else { return free }
        return "\(plan.alreadyOnDeviceCount) already on the iPod · \(free)"
    }

    private func songs(_ count: Int) -> String { "\(count) \(count == 1 ? "song" : "songs")" }
    private func bytes(_ count: Int64) -> String { count.formatted(.byteCount(style: .file)) }
}

#if DEBUG
#Preview("Adding and removing") {
    SyncSummaryBar(plan: SyncPlan(requests: [LibraryTrack.previewTracks[0].syncRequest(preservingAlbumArtist: false)],
                                  removals: [ITunesDatabase.preview.tracks[0]], selectedCount: 3),
                   isCalculating: false, freeBytes: 38_000_000_000, isSyncing: false, onSync: {})
}

#Preview("Up to date") {
    SyncSummaryBar(plan: SyncPlan(requests: [], removals: [], selectedCount: 3), isCalculating: false,
                   freeBytes: 38_000_000_000, isSyncing: false, onSync: {})
}

#Preview("Calculating") {
    SyncSummaryBar(plan: nil, isCalculating: true, freeBytes: 38_000_000_000, isSyncing: false, onSync: {})
}
#endif
