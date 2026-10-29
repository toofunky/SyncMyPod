import Foundation

nonisolated enum ITunesDBRecordBody: Equatable, Sendable {
    /// Bytes after the header whose layout isn't modelled (e.g. an `mhod` payload).
    case opaque(Data)
    /// Children sized by the parent's total length at 0x08. `trailer` keeps unparseable bytes verbatim.
    case container([ITunesDBRecord], trailer: Data)
    /// Children counted by 0x08 and laid out after the header (`mhlt`, `mhlp`, `mhla`, `mhli`).
    case list([ITunesDBRecord])
}
