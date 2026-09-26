import SwiftData
import SwiftUI

@main
struct SyncMyPodApp: App {
    @State private var mountWatcher = IPodMountWatcher()
    @State private var syncModel = IPodSyncModel()
    @State private var updater = AppUpdater()
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(mountWatcher)
                .environment(syncModel)
                .preferredColorScheme(appearance.colorScheme)
        }
        .modelContainer(for: MusicLibrarySchema.models)
        .commands {
            AboutCommand()
            CheckForUpdatesCommand(updater: updater)
            HelpCommand()
        }

        Window("About SyncMyPod", id: AboutView.windowID) {
            AboutView()
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)

        Window("SyncMyPod Help", id: HelpView.windowID) {
            HelpView()
                .preferredColorScheme(appearance.colorScheme)
        }
        .restorationBehavior(.disabled)
    }
}
