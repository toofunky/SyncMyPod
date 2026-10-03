import SwiftUI

struct SyncProgressSheet: View {
    private static let width: CGFloat = 380

    let progress: SyncProgress?
    let result: DeviceSyncResult?
    var deviceKind = "iPod"
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
    private func progressContent(_ progress: SyncProgress) -> some View {
        Text("Syncing \(deviceKind.deviceKindTitle)")
            .font(.headline)
        ProgressView(value: progress.fractionCompleted) {
            Text(progress.currentTitle.map { "Copying “\($0)”" } ?? finishingMessage)
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

    private var finishingMessage: String {
        deviceKind == "iPod" ? "Updating iPod database…" : "Writing playlists…"
    }

    @ViewBuilder
    private func resultContent(_ result: DeviceSyncResult) -> some View {
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

    private func symbol(for result: DeviceSyncResult) -> String {
        switch result {
        case .finished: "checkmark.circle"
        case .failed, .overwritten: "exclamationmark.triangle"
        }
    }
}

#Preview("Copying") {
    SyncProgressSheet(progress: SyncProgress(completed: 3, total: 12, currentTitle: "The Scientist"),
                      result: nil, isCancelling: false, onCancel: {}, onDone: {})
}

#Preview("Finished") {
    SyncProgressSheet(progress: nil,
                      result: .finished(SyncSummary(added: 2, skipped: 3, deviceKind: "iPod")),
                      isCancelling: false, onCancel: {}, onDone: {})
}

#Preview("Overwritten") {
    SyncProgressSheet(progress: nil, result: .overwritten, isCancelling: false, onCancel: {}, onDone: {})
}

#Preview("Failed") {
    SyncProgressSheet(progress: nil,
                      result: .failed("The iPod's iTunesDB has no master playlist.", deviceKind: "iPod"),
                      isCancelling: false, onCancel: {}, onDone: {})
}
