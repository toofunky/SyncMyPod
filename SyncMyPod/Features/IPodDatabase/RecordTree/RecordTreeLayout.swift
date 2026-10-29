import Foundation

/// Which tags a record-tree file uses for its root, counted lists, sized containers and opaque leaves.
nonisolated struct RecordTreeLayout: Sendable {
    let rootTag: String
    let listTags: Set<String>
    let containerTags: Set<String>
    let opaqueTags: Set<String>

    static let iTunesDB = RecordTreeLayout(
        rootTag: "mhbd",
        listTags: ["mhlt", "mhlp", "mhla", "mhli"],
        containerTags: ["mhbd", "mhsd", "mhit", "mhyp", "mhip", "mhia", "mhii"],
        opaqueTags: ["mhod"]
    )

    /// ArtworkDB `mhod`s can nest an `mhni` (which nests a filename `mhod`), so they're containers;
    /// string payloads that aren't records fall through to the container's trailer.
    static let artworkDB = RecordTreeLayout(
        rootTag: "mhfd",
        listTags: ["mhli", "mhla", "mhlf"],
        containerTags: ["mhfd", "mhsd", "mhii", "mhod", "mhni", "mhif", "mhba", "mhia"],
        opaqueTags: []
    )

    func isKnown(_ tag: String) -> Bool {
        listTags.contains(tag) || containerTags.contains(tag) || opaqueTags.contains(tag)
    }
}
