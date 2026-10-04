import SwiftUI

/// Sets up a new player on the volume a person picked, or edits the one already set up there.
struct AudioPlayerSetupSheet: View {
    let location: AudioPlayerLocation
    let onAdd: (AudioPlayerConfig) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var config: AudioPlayerConfig

    init(location: AudioPlayerLocation, existing: AudioPlayerConfig? = nil,
         onAdd: @escaping (AudioPlayerConfig) -> Void) {
        self.location = location
        self.onAdd = onAdd
        var config = existing ?? AudioPlayerConfig(name: location.volumeName, rootPath: location.rootPath)
        config.rootPath = location.rootPath
        _config = State(initialValue: config)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                AudioPlayerConfigFields(config: $config, rootDescription: location.displayPath)
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Add Player") {
                    onAdd(config.cleaned(defaultName: location.volumeName))
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 460)
    }
}

#if DEBUG
#Preview {
    AudioPlayerSetupSheet(location: .preview) { _ in }
}
#endif
