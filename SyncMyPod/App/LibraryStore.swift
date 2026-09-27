import Foundation
import SwiftData

/// Debug builds keep their own library so they never migrate or re-bookmark the release app's store.
enum LibraryStore {
    static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: Schema(MusicLibrarySchema.models),
                                      configurations: ModelConfiguration(url: storeURL))
        } catch {
            fatalError("Couldn't open the library at \(storeURL.path(percentEncoded: false)): \(error)")
        }
    }

    private static var storeURL: URL {
        #if DEBUG
        let folder = URL.applicationSupportDirectory.appending(path: "SyncMyPod Debug", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appending(path: "default.store")
        #else
        URL.applicationSupportDirectory.appending(path: "default.store")
        #endif
    }
}
