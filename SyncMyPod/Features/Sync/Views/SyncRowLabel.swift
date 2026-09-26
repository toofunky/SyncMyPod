import SwiftUI

struct SyncRowLabel: View {
    let title: String
    var systemImage: String?
    let detail: String

    var body: some View {
        HStack {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
            Spacer()
            Text(detail)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    static func detail(trackCount: Int, byteCount: Int64? = nil) -> String {
        let songs = "\(trackCount) \(trackCount == 1 ? "song" : "songs")"
        guard let byteCount else { return songs }
        return "\(songs) · \(byteCount.formatted(.byteCount(style: .file)))"
    }
}

#Preview {
    List {
        SyncRowLabel(title: "Road Trip", systemImage: "music.note.list", detail: SyncRowLabel.detail(trackCount: 24))
        SyncRowLabel(title: "Parachutes", detail: SyncRowLabel.detail(trackCount: 10, byteCount: 82_000_000))
    }
}
