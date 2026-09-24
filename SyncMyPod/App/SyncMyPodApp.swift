import SwiftUI

@main
struct SyncMyPodApp: App {
    @State private var mountWatcher = IPodMountWatcher()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(mountWatcher)
        }
    }
}
