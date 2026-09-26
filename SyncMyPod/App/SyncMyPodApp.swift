import SwiftData
import SwiftUI

@main
struct SyncMyPodApp: App {
    @State private var mountWatcher = IPodMountWatcher()
    @State private var syncModel = IPodSyncModel()
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(mountWatcher)
                .environment(syncModel)
                .preferredColorScheme(appearance.colorScheme)
        }
        .modelContainer(for: MusicLibrarySchema.models)
    }
}
