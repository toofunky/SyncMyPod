import SwiftUI

struct CheckForUpdatesCommand: Commands {
    let updater: AppUpdater

    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button("Check for Updates…") {
                updater.checkForUpdates()
            }
            .disabled(!updater.canCheckForUpdates)
        }
    }
}
