import SwiftUI

/// Stands in for a category's list when its scope is all or none, since there's nothing to choose.
struct SyncScopeNotice: View {
    let category: SyncCategory
    let scope: SyncScope
    var deviceKind = "iPod"

    var body: some View {
        ContentUnavailableView(title, systemImage: category.systemImage, description: Text(description))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var title: String {
        scope == .none ? "No \(category.contentTitle)" : "All \(category.contentTitle)"
    }

    private var description: String {
        let contents = category.contentTitle.lowercased()
        guard scope == .none else { return "Every one of your \(contents) will be copied to the \(deviceKind)." }
        let exception = [.albums, .genres].contains(category) ? ", except songs in synced playlists" : ""
        return "No \(contents) will be copied to the \(deviceKind)\(exception)."
    }
}

#Preview {
    SyncScopeNotice(category: .albums, scope: .none)
}
