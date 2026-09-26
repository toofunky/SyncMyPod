import Foundation

/// A tag's value across the selected songs.
nonisolated enum TagFieldValue: Equatable, Sendable {
    case common(String)
    case mixed

    init(_ values: [String]) {
        let first = values.first ?? ""
        self = values.allSatisfy { $0 == first } ? .common(first) : .mixed
    }

    var commonValue: String {
        if case .common(let value) = self { value } else { "" }
    }

    /// A mixed value counts as edited only once something is typed, so it can't be cleared across songs.
    func isEdited(by text: String) -> Bool {
        switch self {
        case .common(let value): text != value
        case .mixed: !text.isEmpty
        }
    }
}
