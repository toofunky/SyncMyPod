import Foundation

/// Recognises a library file's iPod copy after some of its tags changed: the same duration, and at least
/// two of title, artist and album.
nonisolated enum LooseTrackMatch {
    private static let durationTolerance: TimeInterval = 0.005

    static func matches(_ request: IPodSyncRequest, _ track: ITunesTrack) -> Bool {
        guard request.draft.duration > 0,
              abs(request.draft.duration - track.duration) <= durationTolerance else { return false }
        let file = request.matchKey
        let copy = IPodTrackMatchKey(track)
        return [file.title == copy.title, file.artist == copy.artist, file.album == copy.album]
            .filter { $0 }.count >= 2
    }
}
