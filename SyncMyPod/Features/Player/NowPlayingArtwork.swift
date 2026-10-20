import Foundation

/// Where the player's cover comes from: a podcast's downloaded show artwork, or the art embedded in a book's file.
enum NowPlayingArtwork {
    case podcast(Data?)
    case embedded(path: String?, fingerprint: String?)
}
