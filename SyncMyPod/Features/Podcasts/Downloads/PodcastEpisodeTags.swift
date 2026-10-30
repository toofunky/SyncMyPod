import Foundation

/// What a downloaded episode is tagged with, so players file it under its show rather than as loose songs.
nonisolated struct PodcastEpisodeTags: Equatable, Sendable {
    let title: String
    let show: String
    let author: String
    let publishedAt: Date?
    let episodeNumber: Int?
    /// The show's artwork, embedded only when the episode has none of its own.
    let showArtwork: Data?

    var changes: TagChanges {
        var changes = TagChanges()
        changes.title = title
        changes.artist = author.isEmpty ? show : author
        changes.albumArtist = changes.artist
        changes.album = show
        changes.genre = TrackTags.podcastGenre
        changes.year = publishedAt.map { Calendar(identifier: .gregorian).component(.year, from: $0) }
        changes.track = episodeNumber.map { TagNumberPair(number: $0) }
        return changes
    }
}
