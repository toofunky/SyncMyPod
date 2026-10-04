import SwiftUI

/// Edits a player's setup, saved on the player, and lets SyncMyPod forget it.
struct AudioPlayerSettingsView: View {
    let device: AudioPlayerDevice

    @Environment(DeviceMountWatcher.self) private var watcher
    @Environment(DeviceSyncModel.self) private var syncModel
    @State private var draft: AudioPlayerConfig
    @State private var isConfirmingForget = false
    @State private var errorMessage: String?

    init(device: AudioPlayerDevice) {
        self.device = device
        _draft = State(initialValue: device.config)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                AudioPlayerConfigFields(config: $draft, rootDescription: rootDescription)
                volumeSection
                Section {
                    Button("Forget Player…", role: .destructive) { isConfirmingForget = true }
                        .disabled(syncModel.isSyncing)
                }
            }
            .formStyle(.grouped)
            Divider()
            HStack {
                Text("Moving the music folder moves songs already on the player at the next sync.")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Revert") { draft = device.config }
                    .disabled(draft == device.config)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(draft == device.config || syncModel.isSyncing)
            }
            .padding()
        }
        .confirmationDialog("Forget “\(device.config.name)”?", isPresented: $isConfirmingForget) {
            Button("Forget Player", role: .destructive, action: forget)
        } message: {
            Text("SyncMyPod stops recognizing this player. Music and playlists already on it stay.")
        }
        .alert("Couldn't Save Player Settings", isPresented: isShowingError, presenting: errorMessage) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
    }

    private var rootDescription: String {
        AudioPlayerConfig.join(device.volumeName, device.config.rootPath)
    }

    private var volumeSection: some View {
        Section("Volume") {
            LabeledContent("Capacity", value: Self.format(device.capacityBytes))
            LabeledContent("Free Space", value: Self.format(device.availableBytes))
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func save() {
        let config = draft.cleaned(defaultName: device.volumeName)
        do {
            try device.controlFiles.save(config)
            draft = config
            watcher.add(.audioPlayer(AudioPlayerDevice(volumeURL: device.volumeURL, config: config)))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func forget() {
        do {
            try device.controlFiles.removeConfig()
            watcher.removeDevice(at: device.volumeURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func format(_ bytes: Int64?) -> String {
        bytes.map { $0.formatted(.byteCount(style: .file)) } ?? "Unknown"
    }
}

#if DEBUG
#Preview {
    AudioPlayerSettingsView(device: .preview)
        .environment(DeviceMountWatcher.preview(connectedDevices: [.audioPlayer(.preview)]))
        .environment(DeviceSyncModel())
}
#endif
