import SwiftData
import SwiftUI

@main
struct SyncMyPodApp: App {
    @State private var mountWatcher = IPodMountWatcher()
    @State private var syncModel = IPodSyncModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(mountWatcher)
                .environment(syncModel)
        }
        .modelContainer(for: MusicLibrarySchema.models)
    }
}
