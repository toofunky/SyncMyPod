import Foundation

nonisolated struct IPodMusicFile: Equatable, Sendable {
    /// The iTunesDB location string, e.g. `:iPod_Control:Music:F07:ABCD.m4a`.
    let location: String
    let url: URL
}
