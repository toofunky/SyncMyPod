import SwiftUI

struct SyncProgressSheet: View {
    private static let width: CGFloat = 380

    let progress: IPodSyncProgress?
    let result: IPodSyncResult?
    let isCancelling: Bool
    let onCancel: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            if let result {
                resultContent(result)
            } else if let progress {
                progressContent(progress)
            }
        }
        .padding()
        .frame(width: Self.width)
    }

    @ViewBuilder
    private func progressContent(_ progress: IPodSyncProgress) -> some View {
        Text("Syncing iPod")
            .font(.headline)
        ProgressView(value: progress.fractionCompleted) {
            Text(progress.currentTitle.map { "Copying “\($0)”" } ?? "Updating iPod database…")
                .lineLimit(1)
                .truncationMode(.middle)
        } currentValueLabel: {
            Text(isCancelling ? "Stopping after this song…" : "\(progress.completed) of \(progress.total)")
                .monospacedDigit()
        }
        HStack {
            Spacer()
            Button("Cancel", role: .cancel, action: onCancel)
                .disabled(isCancelling)
        }
    }

    @ViewBuilder
    private func resultContent(_ result: IPodSyncResult) -> some View {
        Label(result.title, systemImage: symbol(for: result))
            .font(.headline)
        Text(result.message)
            .fixedSize(horizontal: false, vertical: true)
        HStack {
            Spacer()
            Button("Done", action: onDone)
                .keyboardShortcut(.defaultAction)
        }
    }

    private func symbol(for result: IPodSyncResult) -> String {
        switch result {
        case .finished: "checkmark.circle"
        case .failed, .overwritten: "exclamationmark.triangle"
        }
    }
}

#Preview("Copying") {
    SyncProgressSheet(progress: IPodSyncProgress(completed: 3, total: 12, currentTitle: "The Scientist"),
                      result: nil, isCancelling: false, onCancel: {}, onDone: {})
}

#Preview("Finished") {
    SyncProgressSheet(progress: nil,
                      result: .finished(IPodSyncOutcome(addedDatabaseIDs: ["/a.m4a": 1, "/b.m4a": 2], skipped: 3)),
                      isCancelling: false, onCancel: {}, onDone: {})
}

#Preview("Overwritten") {
    SyncProgressSheet(progress: nil, result: .overwritten, isCancelling: false, onCancel: {}, onDone: {})
}

#Preview("Failed") {
    SyncProgressSheet(progress: nil, result: .failed("The iPod's iTunesDB has no master playlist."),
                      isCancelling: false, onCancel: {}, onDone: {})
}
