import CoreData
import Foundation

/// Moves the library out of the shared `Application Support/default.store`, which any unsandboxed
/// SwiftData app can open and wipe, into the app's own folder. Leaves the file alone if it isn't ours.
enum LegacyLibraryStoreMigration {
    private static let legacyStoreURL = URL.applicationSupportDirectory.appending(path: "default.store")
    private static let sidecarSuffixes = ["", "-shm", "-wal"]

    static func moveLegacyStore(to storeURL: URL) {
        let manager = FileManager.default
        guard !manager.fileExists(atPath: storeURL.path(percentEncoded: false)),
              manager.fileExists(atPath: legacyStoreURL.path(percentEncoded: false)),
              isLibraryStore(legacyStoreURL) else { return }
        for suffix in sidecarSuffixes {
            let source = URL(filePath: legacyStoreURL.path(percentEncoded: false) + suffix)
            let destination = URL(filePath: storeURL.path(percentEncoded: false) + suffix)
            guard manager.fileExists(atPath: source.path(percentEncoded: false)) else { continue }
            try? manager.moveItem(at: source, to: destination)
        }
    }

    private static func isLibraryStore(_ url: URL) -> Bool {
        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            type: .sqlite, at: url),
              let hashes = metadata[NSStoreModelVersionHashesKey] as? [String: Any] else { return false }
        return hashes.keys.contains(String(describing: LibraryFolder.self))
    }
}
