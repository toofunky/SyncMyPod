import Foundation

nonisolated extension String {
    private static let discFolderPattern = /^(cd|disc|disk)[\s_-]*\d+$/.ignoresCase()

    /// "CD 1", "Disc2" or "disk_3": a folder holding one disc of a book.
    var isDiscFolderName: Bool {
        wholeMatch(of: Self.discFolderPattern) != nil
    }
}
