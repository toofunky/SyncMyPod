import Foundation

/// What grouping needs to know about one scanned audiobook file.
nonisolated struct AudiobookFileSummary: Equatable, Sendable {
    let path: String
    let album: String

    var isM4B: Bool { (path as NSString).pathExtension.lowercased() == "m4b" }
}
