import Foundation

/// Finds manifest paths whose library file is gone for good, so an unplugged music drive never looks like
/// every song was deleted.
nonisolated struct MissingSourceFinder {
    let folderPath: String

    /// Paths inside the library folder that are neither in the library nor on disk. Empty unless the folder,
    /// and at least one library file in it, can be seen right now.
    func missing(_ paths: some Sequence<String>, notIn library: Set<String>) -> Set<String> {
        let manager = FileManager.default
        let root = folderPath.hasSuffix("/") ? folderPath : folderPath + "/"
        guard manager.fileExists(atPath: folderPath),
              library.contains(where: { $0.hasPrefix(root) && manager.fileExists(atPath: $0) }) else { return [] }
        return Set(paths.filter { $0.hasPrefix(root) && !library.contains($0) && !manager.fileExists(atPath: $0) })
    }
}
