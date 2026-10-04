import SwiftData
import SwiftUI

/// Options for what SyncMyPod writes to one iPod, remembered per device.
struct IPodSettingsView: View {
    private static let albumArtistInfo = "When a song's artist differs from its album artist, the song is "
        + "filed under the album artist on the iPod and the guest artist is added to the title — for example, "
        + "\"Song — Guest Artist\". This keeps albums together when you browse by artist. Your music files "
        + "aren't changed."
    private static let lyricsInfo = "When a song has no lyrics of its own, the lyrics in its .lrc lyric file, "
        + "in the same folder and with the same name, are added to the copy on the iPod. Their timings are "
        + "left out, since the iPod shows lyrics as plain text. Your music files aren't changed."

    let device: IPodDevice

    @Environment(\.modelContext) private var context
    @Environment(DeviceSyncModel.self) private var syncModel
    @State private var settings: IPodSyncSettings?

    var body: some View {
        Form {
            if let settings {
                Section {
                    option("Preserve Album Artist?", isOn: Bindable(settings).preservesAlbumArtist,
                           infoTitle: "Preserve Album Artist", info: Self.albumArtistInfo)
                    if device.showsLyrics {
                        option("Sync Lyrics Sidecar?", isOn: Bindable(settings).syncsLyricsSidecars,
                               infoTitle: "Sync Lyrics Sidecar", info: Self.lyricsInfo)
                    }
                } footer: {
                    Text("Songs already on the iPod are updated to match at the next sync.")
                        .foregroundStyle(.secondary)
                }
                .disabled(syncModel.isSyncing)
            }
        }
        .formStyle(.grouped)
        .task(id: device.id) { settings = IPodSyncSettings.settings(for: device.id, in: context) }
    }

    private func option(_ title: String, isOn: Binding<Bool>, infoTitle: String, info: String) -> some View {
        HStack {
            Toggle(title, isOn: isOn)
            InfoPopoverButton(title: infoTitle, message: info)
        }
    }
}

#if DEBUG
#Preview {
    IPodSettingsView(device: .preview)
        .environment(DeviceSyncModel())
        .modelContainer(.preview)
}

#Preview("iPod nano") {
    IPodSettingsView(device: .previewNano)
        .environment(DeviceSyncModel())
        .modelContainer(.preview)
}
#endif
