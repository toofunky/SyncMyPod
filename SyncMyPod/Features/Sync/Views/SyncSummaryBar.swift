import SwiftUI

struct SyncSummaryBar: View {
    let plan: SyncPlan
    let freeBytes: Int64?
    let isSyncing: Bool
    let onSync: () -> Void

    private var fits: Bool { freeBytes.map { plan.byteCount < $0 } ?? true }

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
                .disabled(plan.requests.isEmpty || isSyncing || !fits)
        }
        .padding()
    }

    private var headline: String {
        guard !plan.requests.isEmpty else {
            return plan.selectedCount == 0 ? "Nothing selected" : "Everything selected is on the iPod"
        }
        let size = plan.byteCount.formatted(.byteCount(style: .file))
        return "\(plan.requests.count) \(plan.requests.count == 1 ? "song" : "songs") to add · \(size)"
    }

    private var detail: String {
        let free = freeBytes.map { "\($0.formatted(.byteCount(style: .file))) free" } ?? "Free space unknown"
        guard fits else { return "Not enough space on the iPod · \(free)" }
        return "\(plan.alreadyOnDeviceCount) already on the iPod · \(free)"
    }
}

#Preview("Ready") {
    SyncSummaryBar(plan: SyncPlan(requests: [LibraryTrack.previewTracks[0].syncRequest], selectedCount: 3),
                   freeBytes: 38_000_000_000, isSyncing: false, onSync: {})
}

#Preview("Up to date") {
    SyncSummaryBar(plan: SyncPlan(requests: [], selectedCount: 3), freeBytes: 38_000_000_000,
                   isSyncing: false, onSync: {})
}
