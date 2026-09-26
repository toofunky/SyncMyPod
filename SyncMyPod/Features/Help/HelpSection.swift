import Foundation

struct HelpSection: Identifiable, Hashable, Sendable {
    let heading: String
    let body: String

    var id: String { heading }
}
