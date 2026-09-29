import AppKit
import SwiftUI

struct LibraryScanStatusView: View {
    let folderPath: String
    let trackCount: Int
    let lastScanDate: Date?
    let state: LibraryScanState
    let onCancel: () -> Void

    var body: some View {
        HStack {
            folderLabel
            Text("\(trackCount) songs")
                .foregroundStyle(.secondary)
            Spacer()
            status
        }
        .padding()
    }

    private var folderURL: URL {
        URL(filePath: folderPath, directoryHint: .isDirectory)
    }

    private var showsFullPath: Bool {
        if case .failed = state { return true }
        return false
    }

    private var folderLabel: some View {
        Label(showsFullPath ? folderPath : folderURL.lastPathComponent, systemImage: "folder")
            .lineLimit(1)
            .truncationMode(.middle)
            .help(folderPath)
            .contextMenu {
                Button("Show in Finder", systemImage: "finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([folderURL])
                }
                Button("Copy Path", systemImage: "doc.on.doc") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(folderPath, forType: .string)
                }
            }
    }

    @ViewBuilder
    private var status: some View {
        switch state {
        case .idle:
            if let lastScanDate {
                Text("Scanned \(lastScanDate, format: .relative(presentation: .named))")
                    .foregroundStyle(.secondary)
            }
        case .scanning(let progress):
            ProgressView()
                .controlSize(.small)
            Text("Scanning \(progress.completed) of \(progress.total)…")
                .monospacedDigit()
            Button("Cancel", action: onCancel)
        case .finished(let summary):
            Text(summary.displayText)
                .foregroundStyle(.secondary)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }
}

#Preview("Scanning") {
    LibraryScanStatusView(folderPath: "/Users/me/Music/AAC", trackCount: 1_204, lastScanDate: nil,
                          state: .scanning(LibraryScanProgress(completed: 120, total: 3_400)),
                          onCancel: {})
}

#Preview("Finished") {
    LibraryScanStatusView(folderPath: "/Users/me/Music/AAC", trackCount: 3_398, lastScanDate: .now,
                          state: .finished(LibraryScanSummary(added: 3_398, skipped: 2)),
                          onCancel: {})
}

#Preview("Failed") {
    LibraryScanStatusView(folderPath: "/Users/me/Music/AAC", trackCount: 0, lastScanDate: nil,
                          state: .failed("The folder couldn't be opened."), onCancel: {})
}
