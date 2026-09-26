import SwiftUI

struct HelpCommand: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("SyncMyPod Help") {
                openWindow(id: HelpView.windowID)
            }
            .keyboardShortcut("?", modifiers: .command)
        }
    }
}
