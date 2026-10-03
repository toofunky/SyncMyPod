import SwiftUI
import UniformTypeIdentifiers

/// Picks a player's root folder, then asks how the player is laid out and saves that on the player.
struct AddAudioPlayerButton: View {
    @Environment(DeviceMountWatcher.self) private var watcher
    @State private var isChoosingFolder = false
    @State private var location: AudioPlayerLocation?
    @State private var errorMessage: String?

    var body: some View {
        Button("Add Player…", systemImage: "plus") { isChoosingFolder = true }
            .fileImporter(isPresented: $isChoosingFolder, allowedContentTypes: [.folder]) { result in
                choose(result)
            }
            .fileDialogMessage("Choose the folder on your player's drive or memory card to sync music into.")
            .fileDialogConfirmationLabel("Choose")
            .sheet(item: $location) { location in
                AudioPlayerSetupSheet(location: location,
                                      existing: AudioPlayerControlFiles(volumeURL: location.volumeURL).config()) {
                    save($0, on: location)
                }
            }
            .alert("Couldn't Add Player", isPresented: isShowingError, presenting: errorMessage) { _ in
                Button("OK") {}
            } message: { message in
                Text(message)
            }
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func choose(_ result: Result<URL, any Error>) {
        do {
            location = try AudioPlayerLocation(folder: result.get())
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save(_ config: AudioPlayerConfig, on location: AudioPlayerLocation) {
        do {
            try AudioPlayerControlFiles(volumeURL: location.volumeURL).save(config)
            watcher.add(.audioPlayer(AudioPlayerDevice(volumeURL: location.volumeURL, config: config)))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#if DEBUG
#Preview {
    AddAudioPlayerButton()
        .environment(DeviceMountWatcher.preview())
        .padding()
}
#endif
