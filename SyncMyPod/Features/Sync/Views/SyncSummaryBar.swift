import SwiftUI

struct SyncSummaryBar: View {
    let plan: SyncPlan
    let freeBytes: Int64?
    let isSyncing: Bool
    let onSync: () -> Void

    private var fits: Bool {
        freeBytes.map { plan.byteCount + plan.updatedByteCount < $0 + plan.removedByteCount } ?? true
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
            Button("Sync Now", systemImage: "arrow.triangle.2.circlepath", action: onSync)
                .buttonStyle(.borderedProminent)
                .disabled(plan.isEmpty || isSyncing || !fits)
        }
        .padding()
    }

    private var headline: String {
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
        return parts.joined(separator: " · ")
    }

    private var detail: String {
        let free = freeBytes.map { "\(bytes($0)) free" } ?? "Free space unknown"
        guard fits else { return "Not enough space on the iPod · \(free)" }
        return "\(plan.alreadyOnDeviceCount) already on the iPod · \(free)"
    }

    private func songs(_ count: Int) -> String { "\(count) \(count == 1 ? "song" : "songs")" }
    private func bytes(_ count: Int64) -> String { count.formatted(.byteCount(style: .file)) }
}

#Preview("Adding and removing") {
    SyncSummaryBar(plan: SyncPlan(requests: [LibraryTrack.previewTracks[0].syncRequest],
                                  removals: [ITunesDatabase.preview.tracks[0]], selectedCount: 3),
                   freeBytes: 38_000_000_000, isSyncing: false, onSync: {})
}

#Preview("Up to date") {
    SyncSummaryBar(plan: SyncPlan(requests: [], removals: [], selectedCount: 3), freeBytes: 38_000_000_000,
                   isSyncing: false, onSync: {})
}
