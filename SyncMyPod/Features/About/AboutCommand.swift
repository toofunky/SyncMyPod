import SwiftUI

struct AboutCommand: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About SyncMyPod") {
                openWindow(id: AboutView.windowID)
            }
        }
    }
}
