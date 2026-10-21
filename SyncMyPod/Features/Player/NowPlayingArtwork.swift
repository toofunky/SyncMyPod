import Foundation

/// Where the player's cover comes from: a podcast's downloaded show artwork, or a book's embedded art or cover
/// image file.
enum NowPlayingArtwork {
    case podcast(Data?)
    case embedded(path: String?, fingerprint: String?)
}
