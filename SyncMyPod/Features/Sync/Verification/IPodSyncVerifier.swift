import Foundation

/// Finder and Music can write back their own copy of the database seconds after a sync, undoing it.
nonisolated enum IPodSyncVerifier {
    static let defaultDelay = Duration.seconds(15)

    /// `false` if the database still holds the sync's changes, or can't be read (e.g. the iPod was ejected).
    @concurrent
    static func wasOverwritten(_ expectation: IPodSyncExpectation, onVolume volumeURL: URL,
                               after delay: Duration = defaultDelay) async -> Bool {
        guard (try? await Task.sleep(for: delay)) != nil,
              let data = try? Data(contentsOf: ITunesDBLoader.databaseURL(onVolume: volumeURL)),
              let database = try? ITunesDBParser(data: data).parse() else { return false }
        return !expectation.isMet(by: database)
    }
}
