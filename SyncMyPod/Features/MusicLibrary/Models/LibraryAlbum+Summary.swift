import Foundation

nonisolated extension LibraryAlbum {
    /// "2003 · 12 songs · 54 min", leaving out the year when it isn't tagged.
    func summary(duration: TimeInterval) -> String {
        let songs = trackCount == 1 ? "1 song" : "\(trackCount) songs"
        let minutes = Int((duration / 60).rounded())
        return [yearText, songs, "\(minutes) min"].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
