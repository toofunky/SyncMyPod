import SwiftData
import SwiftUI

/// The app's Settings window, opened from the app menu or with ⌘,.
struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("Podcasts", systemImage: "antenna.radiowaves.left.and.right") {
                PodcastSettingsView()
            }
            Tab("Audiobooks", systemImage: "book.closed") {
                AudiobookSettingsView()
            }
        }
        .frame(width: 500)
    }
}

#if DEBUG
#Preview {
    SettingsView()
        .environment(MediaFolders.preview)
        .modelContainer(.preview)
}
#endif
