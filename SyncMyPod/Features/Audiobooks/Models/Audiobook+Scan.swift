import Foundation

extension Audiobook {
    /// Takes the scanned files and names the book from their tags, falling back to its folder names.
    /// Forgets the listening position when the file it was in is gone.
    func apply(_ group: AudiobookGroup, files newFiles: [AudiobookFile]) {
        if Set(files.map(\.filePath)) != Set(newFiles.map(\.filePath)) { files = newFiles }
        let title = Self.mostCommon(newFiles.map(\.album)) ?? group.fallbackTitle
        let author = Self.mostCommon(newFiles.map(\.albumArtist)) ?? Self.mostCommon(newFiles.map(\.artist))
            ?? group.fallbackAuthor
        if self.title != title { self.title = title }
        if self.author != author { self.author = author }
        if let currentFilePath, !group.filePaths.contains(currentFilePath) {
            self.currentFilePath = nil
            playbackPosition = 0
        }
    }

    private static func mostCommon(_ values: [String]) -> String? {
        let counts = Dictionary(values.filter { !$0.isEmpty }.map { ($0, 1) }, uniquingKeysWith: +)
        return counts.max { $0.value < $1.value || ($0.value == $1.value && $0.key > $1.key) }?.key
    }
}
