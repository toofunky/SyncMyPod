import Foundation

nonisolated extension URL {
    /// Free space on the volume holding this URL; `nil` when it can't be read, such as after an eject.
    var volumeAvailableBytes: Int64? {
        (try? resourceValues(forKeys: [.volumeAvailableCapacityKey]))?.volumeAvailableCapacity.map(Int64.init)
    }
}
