import Foundation

/// One file of the episode or audiobook the player is in.
struct NowPlayingFile {
    let url: URL
    let title: String
    var duration: TimeInterval

    var path: String { url.path(percentEncoded: false) }
}
