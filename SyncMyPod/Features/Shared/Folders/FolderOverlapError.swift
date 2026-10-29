import Foundation

/// A chosen folder lies inside or around another of the app's folders, so scanning one would pick up the
/// other's files.
nonisolated struct FolderOverlapError: LocalizedError, Equatable {
    let chosen: MediaFolderKind
    let existing: MediaFolderKind
    let existingPath: String

    /// The first of the other folders that `path`, chosen as `kind`, lies inside or around.
    static func check(_ path: String, as kind: MediaFolderKind,
                      against folders: [MediaFolderKind: String]) -> FolderOverlapError? {
        for other in MediaFolderKind.allCases where other != kind {
            guard let otherPath = folders[other], FolderOverlap.first(path, in: [otherPath]) != nil else { continue }
            return FolderOverlapError(chosen: kind, existing: other, existingPath: otherPath)
        }
        return nil
    }

    var errorDescription: String? {
        "Your \(chosen.name) folder can't be inside or around your \(existing.name) folder “\(existingPath)”, or "
            + "scanning it would \(consequence). Choose a folder outside it."
    }

    /// The same whichever of the two folders was chosen.
    private var consequence: String {
        switch Set([chosen, existing]) {
        case [.music, .podcasts]: "add every episode to your music library"
        case [.music, .audiobooks]: "add every book to your music library"
        default: "list every episode as an audiobook"
        }
    }
}
