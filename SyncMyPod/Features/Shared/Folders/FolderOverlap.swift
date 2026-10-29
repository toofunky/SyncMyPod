import Foundation

/// The music, podcast and audiobook folders must stay apart, or scanning one would pick up the others' files.
nonisolated enum FolderOverlap {
    /// The first of `others` that `path` lies inside or contains, if any.
    static func first(_ path: String, in others: [String]) -> String? {
        let folder = normalized(path)
        return others.first { other in
            let other = normalized(other)
            return folder.hasPrefix(other) || other.hasPrefix(folder)
        }
    }

    /// With a trailing slash, so "/Music" doesn't count as containing "/Music Podcasts".
    private static func normalized(_ path: String) -> String {
        let standardized = URL(filePath: path, directoryHint: .isDirectory).standardizedFileURL.path(percentEncoded: false)
        return standardized.hasSuffix("/") ? standardized : standardized + "/"
    }
}
