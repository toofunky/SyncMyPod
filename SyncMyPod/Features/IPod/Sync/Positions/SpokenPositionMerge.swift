import Foundation

/// Decides whether a position the iPod changed replaces SyncMyPod's: whichever is further along wins. The iPod
/// keeps 0 for a file it finished, so a changed 0 counts as the end of that file.
nonisolated enum SpokenPositionMerge {
    /// SyncMyPod's new position in the episode, or `nil` to keep its own. A finished episode is back at 0.
    static func episode(app: TimeInterval, device: TimeInterval, duration: TimeInterval?) -> TimeInterval? {
        let deviceProgress = device > 0 ? device : (duration ?? .infinity)
        return deviceProgress > app && device != app ? device : nil
    }

    /// The book's new file index and position, or `nil` to keep SyncMyPod's own. `nil` as the index means the
    /// book was finished and is back at the start. `durations` are the files' in listening order.
    static func book(durations: [TimeInterval], app: (index: Int?, position: TimeInterval),
                     device: (index: Int, position: TimeInterval)) -> (index: Int?, position: TimeInterval)? {
        guard durations.indices.contains(device.index) else { return nil }
        let appProgress = app.index.map { progress(durations, before: $0) + app.position } ?? 0
        let finishedFile = device.position <= 0
        let deviceProgress = progress(durations, before: device.index)
            + (finishedFile ? durations[device.index] : device.position)
        guard deviceProgress > appProgress else { return nil }
        guard finishedFile else { return (device.index, device.position) }
        let next = device.index + 1
        return durations.indices.contains(next) ? (next, 0) : (nil, 0)
    }

    private static func progress(_ durations: [TimeInterval], before index: Int) -> TimeInterval {
        durations.prefix(index).reduce(0, +)
    }
}
