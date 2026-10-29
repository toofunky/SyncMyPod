import Foundation

/// Somewhere library songs can be copied to, such as a connected iPod, supplied by the app so the library
/// needn't know about devices.
struct LibraryAddTarget: Identifiable {
    let id: String
    let name: String
    let systemImage: String
    let add: ([LibraryTrack]) -> Void
}

#if DEBUG
extension LibraryAddTarget {
    static let previews = [LibraryAddTarget(id: "ipod", name: "Michael's iPod", systemImage: "ipod", add: { _ in }),
                           LibraryAddTarget(id: "nano", name: "nano", systemImage: "ipod", add: { _ in })]
}
#endif
