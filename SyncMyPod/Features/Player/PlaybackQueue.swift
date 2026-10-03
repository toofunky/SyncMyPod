import Foundation

/// The songs the player works through, with the order to play them in, which may be shuffled.
struct PlaybackQueue {
    private(set) var tracks: [LibraryTrack] = []
    private(set) var order: [Int] = []
    private(set) var position = 0

    init() {}

    init(tracks: [LibraryTrack], startingAt index: Int, shuffled: Bool) {
        self.tracks = tracks
        order = Array(tracks.indices)
        position = index
        if shuffled { setShuffled(true) }
    }

    var current: LibraryTrack? {
        order.indices.contains(position) ? tracks[order[position]] : nil
    }

    var hasNext: Bool { position + 1 < order.count }

    mutating func advance(wrapping: Bool) -> Bool {
        if hasNext {
            position += 1
        } else if wrapping && !order.isEmpty {
            position = 0
        } else {
            return false
        }
        return true
    }

    mutating func retreat(wrapping: Bool) -> Bool {
        if position > 0 {
            position -= 1
        } else if wrapping && !order.isEmpty {
            position = order.count - 1
        } else {
            return false
        }
        return true
    }

    /// Shuffling puts the current song first; unshuffling carries on in the original order from it.
    mutating func setShuffled(_ shuffled: Bool) {
        guard order.indices.contains(position) else { return }
        let currentIndex = order[position]
        if shuffled {
            order = [currentIndex] + tracks.indices.filter { $0 != currentIndex }.shuffled()
            position = 0
        } else {
            order = Array(tracks.indices)
            position = currentIndex
        }
    }
}
