import Foundation

/// What a song's right-click menu does beyond what it handles itself. A `nil` tag editor hides its item,
/// and a `nil` playlist reveal disables its menu.
struct SongMenuActions {
    var editTags: (([LibraryTrack]) -> Void)?
    var editLyrics: (LibraryTrack) -> Void = { _ in }
    var removeLyrics: (LibraryTrack) -> Void = { _ in }
    var newPlaylist: ([LibraryTrack]) -> Void = { _ in }
    var showPlaylist: ((LibraryPlaylist) -> Void)?
}
