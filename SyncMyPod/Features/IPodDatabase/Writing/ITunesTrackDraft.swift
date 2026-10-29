import Foundation

/// Everything needed to describe a new track in the iTunesDB: its tags, plus where the iPod keeps its file and
/// cover and which menu lists it. Tag fields are read and written as if they were the draft's own.
@dynamicMemberLookup
nonisolated struct ITunesTrackDraft: Equatable, Sendable {
    var tags: TrackTags
    var location = ""
    var artwork: ITunesTrackArtwork?
    /// Podcast episodes and audiobooks are listed in the iPod's Podcasts and Audiobooks menus instead of with the
    /// music, resume where they were left and aren't shuffled.
    var mediaKind = ITunesMediaKind.music

    subscript<Value>(dynamicMember keyPath: WritableKeyPath<TrackTags, Value>) -> Value {
        get { tags[keyPath: keyPath] }
        set { tags[keyPath: keyPath] = newValue }
    }

    subscript<Value>(dynamicMember keyPath: KeyPath<TrackTags, Value>) -> Value {
        tags[keyPath: keyPath]
    }
}
