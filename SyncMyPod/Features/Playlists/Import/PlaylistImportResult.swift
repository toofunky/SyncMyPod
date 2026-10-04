import Foundation

/// The library paths an imported playlist matched, in its order, and how many entries it had.
nonisolated struct PlaylistImportResult: Equatable, Sendable {
    let trackPaths: [String]
    let totalCount: Int

    var missingCount: Int { totalCount - trackPaths.count }

    var summary: String? {
        if totalCount == 0 { return "The playlist file has no songs." }
        if trackPaths.isEmpty { return "None of the songs were found in your library." }
        guard missingCount > 0 else { return nil }
        return "Imported \(trackPaths.count) of \(totalCount) songs; \(missingCount) not found in your library."
    }
}
